// SPDX-License-Identifier: MPL-2.0
//
// list.rs -- Intrusive Doubly-linked List
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

use core::marker::{PhantomData, PhantomPinned};
use core::pin::Pin;
use core::ptr::NonNull;

struct RawNode {
    prev: NonNull<RawNode>,
    next: NonNull<RawNode>,
    _pin: PhantomPinned,
}

pub struct Node<T, Role> {
    node: Option<RawNode>,
    _marker: PhantomData<fn() -> (T, Role)>,
}

impl<T, Role> Node<T, Role> {
    pub unsafe fn new() -> Self {
        Self {
            node: None,
            _marker: PhantomData,
        }
    }
}

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
