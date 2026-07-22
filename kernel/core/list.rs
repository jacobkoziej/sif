// SPDX-License-Identifier: MPL-2.0
//
// list.rs -- Intrusive Doubly-linked List
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

use core::error;
use core::fmt;
use core::marker::{PhantomData, PhantomPinned};
use core::mem::offset_of;
use core::pin::Pin;
use core::ptr::{self, NonNull};

struct RawNode {
    prev: NonNull<RawNode>,
    next: NonNull<RawNode>,
    _pin: PhantomPinned,
}

impl RawNode {
    fn insert(mut prev: NonNull<RawNode>, mut node: NonNull<RawNode>, mut next: NonNull<RawNode>) {
        unsafe {
            prev.as_mut().next = node;
            node.as_mut().prev = prev;
            node.as_mut().next = next;
            next.as_mut().prev = node;
        }
    }

    fn is_singleton(self: &Self) -> bool {
        let ptr = NonNull::from(self);

        self.prev == ptr && self.next == ptr
    }
}

pub struct Node<T, Role> {
    node: RawNode,
    linked: bool,
    _marker: PhantomData<fn() -> (T, Role)>,
}

impl<T, Role> Node<T, Role> {
    pub unsafe fn new() -> Self {
        Self {
            node: RawNode {
                prev: NonNull::dangling(),
                next: NonNull::dangling(),
                _pin: PhantomPinned,
            },
            linked: false,
            _marker: PhantomData,
        }
    }

    fn to_raw_node(self: Pin<&mut Self>) -> Option<NonNull<RawNode>> {
        let this = unsafe { self.get_unchecked_mut() };

        if this.linked {
            return None;
        }

        let this = ptr::from_mut(this);
        let ptr = unsafe { NonNull::new_unchecked(&raw mut (*this).node) };

        unsafe {
            (*ptr.as_ptr()).prev = ptr;
            (*ptr.as_ptr()).next = ptr;
            (*this).linked = true;
        }

        Some(ptr)
    }

    unsafe fn from_raw_node<'a>(node: NonNull<RawNode>) -> Pin<&'a mut Self> {
        unsafe {
            let node = node.byte_sub(offset_of!(Self, node)).cast::<Self>();

            Pin::new_unchecked(&mut *node.as_ptr())
        }
    }

    fn unlink(self: Pin<&mut Self>) {
        let this = unsafe { self.get_unchecked_mut() };

        this.node.prev = NonNull::dangling();
        this.node.next = NonNull::dangling();
        this.linked = false;
    }
}

impl<T, Role> !Sync for Node<T, Role> {}

pub unsafe trait Linked<Role>
where
    Self: Sized,
{
    fn to_node(self: Pin<&mut Self>) -> Pin<&mut Node<Self, Role>>;
    unsafe fn from_node<'a>(node: NonNull<Node<Self, Role>>) -> Pin<&'a mut Self>;
}

pub struct List<T, Role>
where
    T: Linked<Role>,
{
    list: Option<NonNull<RawNode>>,
    _marker: PhantomData<fn() -> (T, Role)>,
}

#[derive(Debug)]
pub enum Error {
    AlreadyInserted,
}

impl fmt::Display for Error {
    fn fmt(self: &Self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        use Error::*;

        match self {
            AlreadyInserted => write!(f, "already inserted"),
        }
    }
}

impl error::Error for Error {}

impl<T, Role> List<T, Role>
where
    T: Linked<Role>,
{
    pub fn append(self: &mut Self, node: Pin<&mut Node<T, Role>>) -> Result<(), Error> {
        let node = node.to_raw_node().ok_or(Error::AlreadyInserted)?;

        let &mut Some(list) = &mut self.list else {
            self.list = Some(node);
            return Ok(());
        };

        unsafe {
            let head = list;
            let tail = head.as_ref().prev;

            RawNode::insert(tail, node, head);
        }

        Ok(())
    }

    pub fn new() -> Self {
        Self {
            list: None,
            _marker: PhantomData,
        }
    }

    pub fn pop_back<'a>(self: &mut Self) -> Option<Pin<&'a mut Node<T, Role>>> {
        let list = &mut self.list;

        let Some(mut head) = *list else {
            return None;
        };

        let mut node = unsafe {
            let mut tail = head.as_mut().prev;

            if tail.as_ref().is_singleton() {
                *list = None;
            } else {
                let mut prev = tail.as_mut().prev;

                head.as_mut().prev = prev;
                prev.as_mut().next = head;
            }

            Node::from_raw_node(tail)
        };

        node.as_mut().unlink();

        Some(node)
    }

    pub fn prepend(self: &mut Self, node: Pin<&mut Node<T, Role>>) -> Result<(), Error> {
        self.append(node)?;

        let node = unsafe { self.list.unwrap().as_ref().prev };

        self.list = Some(node);

        Ok(())
    }
}

impl<T, Role> !Sync for List<T, Role> {}
