// SPDX-License-Identifier: MPL-2.0
//
// list.rs -- instrusive doubly linked list
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

use alloc::alloc::{AllocatorClone, Global};
use alloc::sync::Arc;
use core::alloc::Allocator;
use core::cell::UnsafeCell;
use core::iter::{
    DoubleEndedIterator, ExactSizeIterator, FromIterator, FusedIterator, IntoIterator, Iterator,
};
use core::marker::{PhantomData, PhantomPinned};
use core::mem::{ManuallyDrop, offset_of, transmute};
use core::ops::{Deref, Drop};
use core::ptr::{self, DynMetadata, Pointee};
use core::sync::atomic::{AtomicPtr, Ordering};

pub struct Links {
    prev: AtomicPtr<Self>,
    next: AtomicPtr<Self>,
    _pin: PhantomPinned,
}

impl Links {
    const fn insert(prev: *const Self, node: *const Self, next: *const Self) {
        unsafe {
            (*prev).next.store(node.cast_mut(), Ordering::Relaxed);
            (*node).prev.store(prev.cast_mut(), Ordering::Relaxed);
            (*node).next.store(next.cast_mut(), Ordering::Relaxed);
            (*next).prev.store(node.cast_mut(), Ordering::Relaxed);
        }
    }

    const fn is_locked(&self) -> bool {
        !self.next.load(Ordering::Relaxed).is_null()
    }

    fn is_singleton(&self) -> bool {
        let ptr = ptr::from_ref(self).cast_mut();
        let prev = self.prev.load(Ordering::Relaxed);
        let next = self.next.load(Ordering::Relaxed);

        prev == ptr && next == ptr
    }

    const fn new() -> Self {
        Self {
            prev: AtomicPtr::new(ptr::null_mut()),
            next: AtomicPtr::new(ptr::null_mut()),
            _pin: PhantomPinned,
        }
    }

    const fn next(ptr: *const Self) -> *const Self {
        unsafe { (*ptr).next.load(Ordering::Relaxed).cast_const() }
    }

    const fn prev(ptr: *const Self) -> *const Self {
        unsafe { (*ptr).prev.load(Ordering::Relaxed).cast_const() }
    }

    const fn release(ptr: *const Self) {
        unsafe {
            (*ptr).prev.store(ptr::null_mut(), Ordering::Relaxed);
            (*ptr).next.store(ptr::null_mut(), Ordering::Release);
        }
    }

    const fn remove(prev: *const Self, node: *const Self, next: *const Self) {
        unsafe {
            (*prev).next.store(next.cast_mut(), Ordering::Relaxed);
            (*next).prev.store(prev.cast_mut(), Ordering::Relaxed);

            (*node).prev.store(node.cast_mut(), Ordering::Relaxed);
            (*node).next.store(node.cast_mut(), Ordering::Relaxed);
        }
    }

    fn try_claim(ptr: *const Self) -> bool {
        let node = unsafe { &*ptr };

        let claimed = node
            .next
            .compare_exchange(
                ptr::null_mut(),
                ptr.cast_mut(),
                Ordering::Acquire,
                Ordering::Relaxed,
            )
            .is_ok();

        if !claimed {
            return false;
        }

        node.prev.store(ptr.cast_mut(), Ordering::Relaxed);

        true
    }
}

pub trait InnerLinks {
    fn as_links(ptr: *const Self) -> *const Links;
    unsafe fn from_links(ptr: *const Links) -> *const Self;
}

struct LinksIter {
    front: *const Links,
    back: *const Links,
}

impl LinksIter {
    const fn new(node: *const Links) -> Self {
        if node.is_null() {
            return Self {
                front: ptr::null(),
                back: ptr::null(),
            };
        }

        Self {
            front: node,
            back: Links::prev(node),
        }
    }
}

impl DoubleEndedIterator for LinksIter {
    fn next_back(&mut self) -> Option<Self::Item> {
        if self.back.is_null() {
            return None;
        }

        let node = self.back;

        if self.front == self.back {
            self.front = ptr::null();
            self.back = ptr::null();
        } else {
            self.back = Links::prev(self.back);
        }

        Some(node)
    }
}

impl FusedIterator for LinksIter {}

impl Iterator for LinksIter {
    type Item = *const Links;

    fn next(&mut self) -> Option<Self::Item> {
        if self.front.is_null() {
            return None;
        }

        let node = self.front;

        if self.front == self.back {
            self.front = ptr::null();
            self.back = ptr::null();
        } else {
            self.front = Links::next(self.front);
        }

        Some(node)
    }
}

pub trait Role {}

pub struct Node<R: Role> {
    links: Links,
    _marker: PhantomData<fn() -> R>,
}

impl<R> Node<R>
where
    R: Role,
{
    pub const unsafe fn new() -> Self {
        Self {
            links: Links::new(),
            _marker: PhantomData,
        }
    }
}

impl<R> InnerLinks for Node<R>
where
    R: Role,
{
    fn as_links(ptr: *const Self) -> *const Links {
        unsafe { &raw const (*ptr).links }
    }

    unsafe fn from_links(ptr: *const Links) -> *const Self {
        let offset = offset_of!(Self, links);

        unsafe { ptr.byte_sub(offset).cast::<Self>() }
    }
}

unsafe impl<R: Role> Send for Node<R> {}
unsafe impl<R: Role> Sync for Node<R> {}

pub struct DynNode<R: Role> {
    links: Links,
    data: UnsafeCell<*const ()>,
    meta: UnsafeCell<*const ()>,
    _marker: PhantomData<fn() -> R>,
    _pin: PhantomPinned,
}

impl<R> DynNode<R>
where
    R: Role,
{
    pub const unsafe fn new() -> Self {
        Self {
            links: Links::new(),
            data: UnsafeCell::new(ptr::null()),
            meta: UnsafeCell::new(ptr::null()),
            _marker: PhantomData,
            _pin: PhantomPinned,
        }
    }
}

impl<R> InnerLinks for DynNode<R>
where
    R: Role,
{
    fn as_links(ptr: *const Self) -> *const Links {
        unsafe { &raw const (*ptr).links }
    }

    unsafe fn from_links(ptr: *const Links) -> *const Self {
        let offset = offset_of!(Self, links);

        unsafe { ptr.byte_sub(offset).cast::<Self>() }
    }
}

unsafe impl<R: Role> Send for DynNode<R> {}
unsafe impl<R: Role> Sync for DynNode<R> {}

pub unsafe trait Linkable<R: Role> {
    fn as_links(ptr: *const Self) -> *const Links;
    unsafe fn from_links(ptr: *const Links) -> *const Self;
}

#[macro_export]
macro_rules! linkable {
    ($ty:ty, $role:ty, $field:ident) => {
        unsafe impl $crate::list::Linkable<$role> for $ty {
            fn as_links(ptr: *const Self) -> *const $crate::list::Links {
                let node = unsafe { &raw const (*ptr).$field };

                $crate::list::InnerLinks::as_links(node)
            }

            unsafe fn from_links(ptr: *const $crate::list::Links) -> *const Self {
                let node: *const $crate::list::Node<$role> =
                    unsafe { $crate::list::InnerLinks::from_links(ptr) };
                let offset = ::core::mem::offset_of!(Self, $field);

                unsafe { node.byte_sub(offset).cast::<Self>() }
            }
        }
    };
}

pub unsafe trait DynLinkable<R: Role> {
    fn as_dyn_node(&self) -> *const DynNode<R>;
}

unsafe impl<T, R> Linkable<R> for T
where
    T: ?Sized + DynLinkable<R> + Pointee<Metadata = DynMetadata<T>>,
    R: Role,
{
    fn as_links(ptr: *const T) -> *const Links {
        let node = unsafe { &*<T as DynLinkable<R>>::as_dyn_node(&*ptr) };

        if node.links.is_locked() {
            let (data, meta) = ptr.to_raw_parts();

            unsafe {
                *node.data.get() = data;
                *node.meta.get() = transmute(meta);
            }
        }

        InnerLinks::as_links(node)
    }

    unsafe fn from_links(ptr: *const Links) -> *const T {
        unsafe {
            let node: &DynNode<R> = &*InnerLinks::from_links(ptr);
            let meta: DynMetadata<T> = transmute(*node.meta.get());

            ptr::from_raw_parts(*node.data.get(), meta)
        }
    }
}

#[macro_export]
macro_rules! dyn_linkable {
    ($ty:ty, $role:ty, $field:ident) => {
        unsafe impl $crate::list::DynLinkable<$role> for $ty {
            fn as_dyn_node(&self) -> *const $crate::list::DynNode<$role> {
                ::core::ptr::from_ref(&self.$field)
            }
        }
    };
}

pub struct Token<T, R, A = Global>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: Allocator,
{
    arc: Arc<T, A>,
    _marker: PhantomData<fn() -> R>,
}

impl<T, R, A> Token<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: Allocator,
{
    unsafe fn from_raw_in(ptr: *const T, alloc: A) -> Self {
        Self {
            arc: unsafe { Arc::from_raw_in(ptr, alloc) },
            _marker: PhantomData,
        }
    }

    fn into_raw(self) -> *const T {
        let this = ManuallyDrop::new(self);
        let arc = unsafe { ptr::read(&this.arc) };
        let (ptr, _alloc) = Arc::into_raw_with_allocator(arc);

        ptr
    }
}

impl<T, R, A> Token<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    pub fn try_from_arc(arc: &Arc<T, A>) -> Option<Self> {
        let ptr = Arc::as_ptr(arc);

        let links = T::as_links(ptr);

        if !Links::try_claim(links) {
            return None;
        }

        Some(Self {
            arc: Arc::clone(arc),
            _marker: PhantomData,
        })
    }
}

impl<T, R, A> Deref for Token<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: Allocator,
{
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.arc
    }
}

impl<T, R, A> Drop for Token<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: Allocator,
{
    fn drop(&mut self) {
        let links = T::as_links(&*self.arc);

        Links::release(links);
    }
}

pub struct List<T, R, A = Global>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    ptr: *const Links,
    len: usize,
    alloc: A,
    _marker: PhantomData<fn() -> (*const T, R)>,
}

impl<T, R> List<T, R>
where
    T: ?Sized + Linkable<R>,
    R: Role,
{
    pub const fn new() -> Self {
        Self::new_in(Global)
    }
}

impl<T, R, A> List<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    fn get_item(&self, ptr: *const Links) -> Arc<T, A> {
        let item = unsafe { T::from_links(ptr) };

        let arc = ManuallyDrop::new(unsafe { Arc::from_raw_in(item, self.alloc.clone()) });

        Arc::clone(&arc)
    }

    pub fn head(&self) -> Option<Arc<T, A>> {
        if self.is_empty() {
            return None;
        }

        let head = self.ptr;

        Some(self.get_item(head))
    }

    pub const fn is_empty(&self) -> bool {
        self.ptr.is_null()
    }

    pub const fn len(&self) -> usize {
        self.len
    }

    pub const fn new_in(alloc: A) -> Self {
        Self {
            ptr: ptr::null(),
            len: 0,
            alloc,
            _marker: PhantomData,
        }
    }

    pub fn pop_back(&mut self) -> Option<Token<T, R, A>> {
        if self.is_empty() {
            return None;
        }

        let head = self.ptr;
        let tail = Links::prev(head);

        if unsafe { &*head }.is_singleton() {
            self.ptr = ptr::null();
        }

        Links::remove(Links::prev(tail), tail, head);

        self.len -= 1;

        let item = unsafe { T::from_links(tail) };

        Some(unsafe { Token::from_raw_in(item, self.alloc.clone()) })
    }

    pub fn pop_front(&mut self) -> Option<Token<T, R, A>> {
        if self.is_empty() {
            return None;
        }

        let head = self.ptr;
        let tail = Links::prev(head);

        if unsafe { &*head }.is_singleton() {
            self.ptr = ptr::null();
        } else {
            self.ptr = Links::next(head);
        }

        Links::remove(tail, head, Links::next(head));

        self.len -= 1;

        let item = unsafe { T::from_links(head) };

        Some(unsafe { Token::from_raw_in(item, self.alloc.clone()) })
    }

    pub fn push_front(&mut self, arc: Token<T, R, A>) {
        let node = T::as_links(arc.into_raw());

        if self.is_empty() {
            Links::insert(node, node, node);
        } else {
            let head = self.ptr;
            let tail = Links::prev(head);

            Links::insert(tail, node, head);
        }

        self.ptr = node;
        self.len += 1;
    }

    pub fn push_back(&mut self, arc: Token<T, R, A>) {
        let node = T::as_links(arc.into_raw());

        if self.is_empty() {
            Links::insert(node, node, node);

            self.ptr = node;
            self.len += 1;

            return;
        }

        let head = self.ptr;
        let tail = Links::prev(head);

        Links::insert(tail, node, head);

        self.len += 1;
    }

    pub fn tail(&self) -> Option<Arc<T, A>> {
        if self.is_empty() {
            return None;
        }

        let head = self.ptr;
        let tail = Links::prev(head);

        Some(self.get_item(tail))
    }
}

impl<T, R, A> Drop for List<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    fn drop(&mut self) {
        while self.pop_front().is_some() {}
    }
}

impl<T, R> FromIterator<Token<T, R>> for List<T, R>
where
    T: ?Sized + Linkable<R>,
    R: Role,
{
    fn from_iter<I: IntoIterator<Item = Token<T, R>>>(iter: I) -> Self {
        let mut list = List::<T, R>::new();

        for i in iter {
            list.push_back(i)
        }

        list
    }
}

impl<T, R, A> IntoIterator for List<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    type Item = Token<T, R, A>;
    type IntoIter = IntoIter<T, R, A>;

    fn into_iter(self) -> Self::IntoIter {
        Self::IntoIter::new(self)
    }
}

impl<'a, T, R, A> IntoIterator for &'a List<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    type Item = &'a T;
    type IntoIter = Iter<'a, T, R, A>;

    fn into_iter(self) -> Self::IntoIter {
        Self::IntoIter::new(self)
    }
}

unsafe impl<T, R, A> Send for List<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone + Send,
{
}

pub struct Iter<'a, T, R, A = Global>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    links: LinksIter,
    len: usize,
    _list: PhantomData<&'a List<T, R, A>>,
}

impl<'a, T, R, A> Iter<'a, T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    pub fn new(list: &'a List<T, R, A>) -> Self {
        Self {
            links: LinksIter::new(list.ptr),
            len: list.len(),
            _list: PhantomData,
        }
    }
}

impl<'a, T, R, A> DoubleEndedIterator for Iter<'a, T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    fn next_back(&mut self) -> Option<Self::Item> {
        let ptr = self.links.next_back()?;

        self.len -= 1;

        Some(unsafe { &*T::from_links(ptr) })
    }
}

impl<'a, T, R, A> ExactSizeIterator for Iter<'a, T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    fn len(&self) -> usize {
        self.len
    }
}

impl<'a, T, R, A> FusedIterator for Iter<'a, T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
}

impl<'a, T, R, A> Iterator for Iter<'a, T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    type Item = &'a T;

    fn next(&mut self) -> Option<Self::Item> {
        let ptr = self.links.next()?;

        self.len -= 1;

        Some(unsafe { &*T::from_links(ptr) })
    }
}

pub struct IntoIter<T, R, A = Global>(List<T, R, A>)
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone;

impl<T, R, A> IntoIter<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    pub fn new(list: List<T, R, A>) -> Self {
        Self(list)
    }
}

impl<T, R, A> DoubleEndedIterator for IntoIter<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    fn next_back(&mut self) -> Option<Self::Item> {
        self.0.pop_back()
    }
}

impl<T, R, A> ExactSizeIterator for IntoIter<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    fn len(&self) -> usize {
        self.0.len()
    }
}

impl<T, R, A> FusedIterator for IntoIter<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
}

impl<T, R, A> Iterator for IntoIter<T, R, A>
where
    T: ?Sized + Linkable<R>,
    R: Role,
    A: AllocatorClone,
{
    type Item = Token<T, R, A>;

    fn next(&mut self) -> Option<Self::Item> {
        self.0.pop_front()
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use core::pin::{Pin, pin};

    struct Foo;
    impl Role for Foo {}

    struct Bar;
    impl Role for Bar {}

    trait ItemLike: DynLinkable<Bar> {
        fn value(&self) -> u64;
    }

    struct Item {
        data: u32,
        foo: Node<Foo>,
        bar: DynNode<Bar>,
    }

    impl Item {
        fn new(data: u32) -> Self {
            Self {
                data,
                foo: unsafe { Node::new() },
                bar: unsafe { DynNode::new() },
            }
        }
    }

    linkable! {Item, Foo, foo}
    dyn_linkable! {Item, Bar, bar}

    impl ItemLike for Item {
        fn value(&self) -> u64 {
            self.data as u64
        }
    }

    const _: () = {
        fn check<T: Send + Sync>() {}
        let _ = check::<Node<Foo>>;
    };

    const _: () = {
        fn check<T: Send + Sync>() {}
        let _ = check::<DynNode<Bar>>;
    };

    const _: () = {
        fn check<T: Send + Sync>() {}
        let _ = check::<Token<Item, Foo>>;
    };

    const _: () = {
        fn check<T: Send>() {}
        let _ = check::<List<Item, Foo>>;
    };

    fn ptr(node: Pin<&Links>) -> *const Links {
        ptr::from_ref(node.get_ref())
    }

    fn token(data: u32) -> Token<Item, Foo> {
        Token::try_from_arc(&Arc::new(Item::new(data))).unwrap()
    }

    mod links {
        use super::*;
        use core::pin::{Pin, pin};

        fn prev(node: Pin<&Links>) -> *const Links {
            Links::prev(ptr(node))
        }

        fn next(node: Pin<&Links>) -> *const Links {
            Links::next(ptr(node))
        }

        fn assert_ring(nodes: &[Pin<&Links>]) {
            let n = nodes.len();
            let expected: Vec<_> = nodes.iter().map(|node| ptr(*node)).collect();

            assert!(LinksIter::new(expected[0]).eq(expected.iter().copied()));

            for i in 0..n {
                let prev = ptr(nodes[(i + n - 1) % n]);
                let next = ptr(nodes[(i + 1) % n]);

                assert_eq!(self::prev(nodes[i]), prev);
                assert_eq!(self::next(nodes[i]), next);
            }
        }

        #[test]
        fn insert() {
            let a = pin!(Links::new());
            let a = a.into_ref();
            let b = pin!(Links::new());
            let b = b.into_ref();

            Links::insert(ptr(b), ptr(a), ptr(b));
            assert_ring(&[a, b]);

            let c = pin!(Links::new());
            let c = c.into_ref();

            Links::insert(ptr(b), ptr(c), ptr(a));
            assert_ring(&[a, b, c]);
        }

        #[test]
        fn is_singleton() {
            let node = pin!(Links::new());
            let node = node.into_ref();

            assert!(!node.is_singleton());

            Links::insert(ptr(node), ptr(node), ptr(node));

            assert!(node.is_singleton());
        }

        #[test]
        fn remove() {
            let a = pin!(Links::new());
            let a = a.into_ref();
            let b = pin!(Links::new());
            let b = b.into_ref();
            let c = pin!(Links::new());
            let c = c.into_ref();

            Links::insert(ptr(b), ptr(a), ptr(b));
            Links::insert(ptr(b), ptr(c), ptr(a));

            Links::remove(ptr(b), ptr(c), ptr(a));

            assert!(c.is_singleton());
            assert_ring(&[a, b]);

            Links::remove(ptr(b), ptr(a), ptr(b));

            assert!(a.is_singleton());
            assert!(b.is_singleton());

            Links::remove(ptr(b), ptr(b), ptr(b));

            assert!(b.is_singleton());
        }
    }

    mod links_iter {
        use super::*;

        #[test]
        fn empty() {
            let mut iter = LinksIter::new(ptr::null());

            assert_eq!(iter.next(), None);
            assert_eq!(iter.next_back(), None);
            assert_eq!(iter.next(), None);
            assert_eq!(iter.next_back(), None);
        }

        #[test]
        fn unlinked() {
            let node = pin!(Links::new());
            let node = node.into_ref();

            let mut iter = LinksIter::new(ptr(node));

            assert_eq!(iter.next(), Some(ptr(node)));
            assert_eq!(iter.next(), None);
            assert_eq!(iter.next_back(), None);
        }

        #[test]
        fn singleton() {
            let node = pin!(Links::new());
            let node = node.into_ref();

            Links::insert(ptr(node), ptr(node), ptr(node));

            let mut iter = LinksIter::new(ptr(node));

            assert_eq!(iter.next(), Some(ptr(node)));
            assert_eq!(iter.next(), None);
            assert_eq!(iter.next_back(), None);

            let mut iter = LinksIter::new(ptr(node));

            assert_eq!(iter.next_back(), Some(ptr(node)));
            assert_eq!(iter.next_back(), None);
            assert_eq!(iter.next(), None);
        }

        #[test]
        fn forward_three() {
            let a = pin!(Links::new());
            let a = a.into_ref();
            let b = pin!(Links::new());
            let b = b.into_ref();
            let c = pin!(Links::new());
            let c = c.into_ref();

            Links::insert(ptr(b), ptr(a), ptr(b));
            Links::insert(ptr(b), ptr(c), ptr(a));

            assert!(LinksIter::new(ptr(a)).eq([ptr(a), ptr(b), ptr(c)]));
        }

        #[test]
        fn rev_three() {
            let a = pin!(Links::new());
            let a = a.into_ref();
            let b = pin!(Links::new());
            let b = b.into_ref();
            let c = pin!(Links::new());
            let c = c.into_ref();

            Links::insert(ptr(b), ptr(a), ptr(b));
            Links::insert(ptr(b), ptr(c), ptr(a));

            assert!(LinksIter::new(ptr(a)).rev().eq([ptr(c), ptr(b), ptr(a)]));
        }

        #[test]
        fn both_ends_three() {
            let a = pin!(Links::new());
            let a = a.into_ref();
            let b = pin!(Links::new());
            let b = b.into_ref();
            let c = pin!(Links::new());
            let c = c.into_ref();

            Links::insert(ptr(b), ptr(a), ptr(b));
            Links::insert(ptr(b), ptr(c), ptr(a));

            let mut iter = LinksIter::new(ptr(a));

            assert_eq!(iter.next(), Some(ptr(a)));
            assert_eq!(iter.next_back(), Some(ptr(c)));
            assert_eq!(iter.next(), Some(ptr(b)));
            assert_eq!(iter.next(), None);
            assert_eq!(iter.next_back(), None);
        }
    }

    mod dyn_node {
        use super::*;

        struct Thing {
            data: i32,
            node: DynNode<Bar>,
        }

        impl Thing {
            fn new(data: i32) -> Self {
                Self {
                    data,
                    node: unsafe { DynNode::new() },
                }
            }
        }

        dyn_linkable! {Thing, Bar, node}

        impl ItemLike for Thing {
            fn value(&self) -> u64 {
                self.data as u64
            }
        }

        fn claim<R: Role>(node: *const DynNode<R>) {
            assert!(Links::try_claim(InnerLinks::as_links(node)));
        }

        fn same_ptr<T: ?Sized>(left: *const T, right: *const T) -> bool {
            if !ptr::eq(left.cast::<()>(), right.cast::<()>()) {
                return false;
            }

            ptr::metadata(left) == ptr::metadata(right)
        }

        #[test]
        fn as_dyn_node_returns_field() {
            let thing = Thing::new(1);

            assert!(ptr::eq(
                DynLinkable::<Bar>::as_dyn_node(&thing),
                ptr::from_ref(&thing.node),
            ));
        }

        #[test]
        fn blanket_stores_and_reads_pointer() {
            let thing = Thing::new(-2);
            let object: *const dyn ItemLike = &thing;

            claim(thing.as_dyn_node());

            let links = <dyn ItemLike as Linkable<Bar>>::as_links(object);
            let ptr = unsafe { <dyn ItemLike as Linkable<Bar>>::from_links(links) };

            assert!(same_ptr(object, ptr));

            assert_eq!(unsafe { &*ptr }.value(), -2i32 as u64);
        }

        #[test]
        fn distinct_trait_objects() {
            let item = Item::new(1);
            let thing = Thing::new(-2);
            let item_object: *const dyn ItemLike = &item;
            let thing_object: *const dyn ItemLike = &thing;

            claim(DynLinkable::<Bar>::as_dyn_node(&item));
            claim(thing.as_dyn_node());

            let item_links = <dyn ItemLike as Linkable<Bar>>::as_links(item_object);
            let thing_links = <dyn ItemLike as Linkable<Bar>>::as_links(thing_object);
            let loaded_item = unsafe { <dyn ItemLike as Linkable<Bar>>::from_links(item_links) };
            let loaded_thing = unsafe { <dyn ItemLike as Linkable<Bar>>::from_links(thing_links) };

            assert!(same_ptr(item_object, loaded_item));
            assert!(same_ptr(thing_object, loaded_thing));
            assert!(!same_ptr(loaded_item, loaded_thing));

            assert_eq!(unsafe { &*loaded_item }.value(), 1);
            assert_eq!(unsafe { &*loaded_thing }.value(), -2i32 as u64);
        }

        #[test]
        fn relock_stores_other_trait_object() {
            trait Other: DynLinkable<Bar> {
                fn tag(&self) -> i32;
            }

            impl Other for Thing {
                fn tag(&self) -> i32 {
                    self.data
                }
            }

            let thing = Thing::new(-2);
            let like: *const dyn ItemLike = &thing;
            let other: *const dyn Other = &thing;

            let links = InnerLinks::as_links(thing.as_dyn_node());

            assert!(Links::try_claim(links));

            let like_links = <dyn ItemLike as Linkable<Bar>>::as_links(like);
            let loaded_like = unsafe { <dyn ItemLike as Linkable<Bar>>::from_links(like_links) };

            assert!(same_ptr(like, loaded_like));

            assert_eq!(unsafe { &*loaded_like }.value(), -2i32 as u64);

            Links::release(links);

            assert!(Links::try_claim(links));

            let other_links = <dyn Other as Linkable<Bar>>::as_links(other);
            let loaded_other = unsafe { <dyn Other as Linkable<Bar>>::from_links(other_links) };

            assert!(same_ptr(other, loaded_other));

            assert_eq!(unsafe { &*loaded_other }.tag(), -2);
        }
    }

    mod token {
        use super::*;
        use std::env;
        use std::str::FromStr;
        use std::thread;

        fn env_read<T: FromStr>(name: &str, default: T) -> T {
            env::var(name)
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(default)
        }

        #[test]
        fn only_mints_for_unclaimed() {
            let arc = Arc::new(Item::new(0));

            let foo = Token::<_, Foo>::try_from_arc(&arc);

            assert!(foo.is_some());

            assert!(Token::<_, Foo>::try_from_arc(&arc).is_none());
        }

        #[test]
        fn into_raw_skips_drop() {
            let arc = Arc::new(Item::new(0));
            let foo = Token::<_, Foo>::try_from_arc(&arc).unwrap();

            assert_eq!(Arc::strong_count(&arc), 2);

            let ptr = Token::into_raw(foo);

            assert_eq!(Arc::strong_count(&arc), 2);
            assert!(Token::<_, Foo>::try_from_arc(&arc).is_none());

            let foo = unsafe { Token::<_, Foo>::from_raw_in(ptr, Global) };

            assert_eq!(Arc::strong_count(&arc), 2);

            drop(foo);

            assert_eq!(Arc::strong_count(&arc), 1);
        }

        #[test]
        fn drop_releases_claim() {
            let arc = Arc::new(Item::new(0));

            let foo = Token::<_, Foo>::try_from_arc(&arc).unwrap();

            drop(foo);

            assert!(Token::<_, Foo>::try_from_arc(&arc).is_some());
        }

        #[test]
        fn deref_item() {
            let arc = Arc::new(Item::new(1));

            let foo = Token::<_, Foo>::try_from_arc(&arc).unwrap();

            assert_eq!(foo.data, 1);
            assert!(ptr::eq(arc.as_ref(), &*foo));
        }

        #[test]
        fn multithreaded_minting() {
            let threads = env_read::<usize>("LISTARC_THREADS", 8).max(1);
            let iters = env_read::<usize>("LISTARC_ITERATIONS", 1_000);

            let arc = Arc::new(Item::new(0));

            thread::scope(|s| {
                for _ in 0..threads {
                    let arc = &arc;

                    s.spawn(move || {
                        for _ in 0..iters {
                            drop(Token::<Item, Foo>::try_from_arc(arc));
                        }
                    });
                }
            });

            assert_eq!(Arc::strong_count(&arc), 1);
            assert!(Token::<_, Foo>::try_from_arc(&arc).is_some());
        }
    }

    mod list {
        use super::*;

        #[test]
        fn empty() {
            let mut list = List::<Item, Foo>::new();

            assert!(list.is_empty());
            assert_eq!(list.len(), 0);
            assert!(list.head().is_none());
            assert!(list.tail().is_none());
            assert!(list.pop_front().is_none());
            assert!(list.pop_back().is_none());
        }

        #[test]
        fn push_pop_front() {
            let mut list = List::new();

            for data in [0, 1, 2] {
                list.push_front(token(data));
            }

            assert!(!list.is_empty());
            assert_eq!(list.len(), 3);

            assert_eq!(list.head().unwrap().data, 2);
            assert_eq!(list.tail().unwrap().data, 0);

            assert_eq!(list.pop_front().unwrap().data, 2);

            assert_eq!(list.head().unwrap().data, 1);
            assert_eq!(list.tail().unwrap().data, 0);
        }

        #[test]
        fn push_pop_back() {
            let mut list = List::new();

            for data in [0, 1, 2] {
                list.push_back(token(data));
            }

            assert!(!list.is_empty());
            assert_eq!(list.len(), 3);

            assert_eq!(list.head().unwrap().data, 0);
            assert_eq!(list.tail().unwrap().data, 2);

            assert_eq!(list.pop_back().unwrap().data, 2);

            assert_eq!(list.head().unwrap().data, 0);
            assert_eq!(list.tail().unwrap().data, 1);
        }
    }

    mod iter {
        use super::*;

        #[test]
        fn iter_round_trip() {
            let src = [0, 1, 2];

            let list: List<Item, Foo> = src.into_iter().map(token).collect();

            assert!((&list).into_iter().map(|item| item.data).eq(src));
            assert!(
                (&list)
                    .into_iter()
                    .rev()
                    .map(|item| item.data)
                    .eq(src.into_iter().rev())
            );
        }

        #[test]
        fn into_iter_round_trip() {
            let src = [0, 1, 2];

            let forward: List<Item, Foo> = src.into_iter().map(token).collect();
            let reverse: List<Item, Foo> = src.into_iter().map(token).collect();

            assert!(forward.into_iter().map(|item| item.data).eq(src));
            assert!(
                reverse
                    .into_iter()
                    .rev()
                    .map(|item| item.data)
                    .eq(src.into_iter().rev())
            );
        }

        #[test]
        fn iter_exact_size() {
            let list = List::<Item, Foo>::new();
            let mut iter = (&list).into_iter();

            assert_eq!(iter.len(), 0);
            assert!(iter.next().is_none());
            assert!(iter.next_back().is_none());
            assert_eq!(iter.len(), 0);

            let list: List<Item, Foo> = [0, 1, 2].into_iter().map(token).collect();
            let mut iter = (&list).into_iter();

            assert_eq!(iter.len(), 3);
            assert_eq!(iter.next().unwrap().data, 0);
            assert_eq!(iter.len(), 2);
            assert_eq!(iter.next_back().unwrap().data, 2);
            assert_eq!(iter.len(), 1);
            assert_eq!(iter.next().unwrap().data, 1);
            assert_eq!(iter.len(), 0);
            assert!(iter.next().is_none());
            assert!(iter.next_back().is_none());
            assert_eq!(iter.len(), 0);
        }

        #[test]
        fn into_iter_exact_size() {
            let list = List::<Item, Foo>::new();
            let mut iter = list.into_iter();

            assert_eq!(iter.len(), 0);
            assert!(iter.next().is_none());
            assert!(iter.next_back().is_none());
            assert_eq!(iter.len(), 0);

            let list: List<Item, Foo> = [0, 1, 2].into_iter().map(token).collect();
            let mut iter = list.into_iter();

            assert_eq!(iter.len(), 3);
            assert_eq!(iter.next().unwrap().data, 0);
            assert_eq!(iter.len(), 2);
            assert_eq!(iter.next_back().unwrap().data, 2);
            assert_eq!(iter.len(), 1);
            assert_eq!(iter.next().unwrap().data, 1);
            assert_eq!(iter.len(), 0);
            assert!(iter.next().is_none());
            assert!(iter.next_back().is_none());
            assert_eq!(iter.len(), 0);
        }
    }
}
