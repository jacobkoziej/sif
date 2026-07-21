// SPDX-License-Identifier: MPL-2.0
//
// list.rs -- Intrusive Doubly-linked List
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

use core::marker::{PhantomData, PhantomPinned};
use core::mem::offset_of;
use core::pin::Pin;
use core::ptr::{self, NonNull};

struct RawNode {
    prev: NonNull<RawNode>,
    next: NonNull<RawNode>,
    _pin: PhantomPinned,
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

impl<T, Role> List<T, Role>
where
    T: Linked<Role>,
{
    pub fn new() -> Self {
        Self {
            list: None,
            _marker: PhantomData,
        }
    }
}

impl<T, Role> !Sync for List<T, Role> {}
