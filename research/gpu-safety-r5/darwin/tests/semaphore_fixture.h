// SPDX-License-Identifier: MIT
// CPU-only injected system boundary; not an XNU implementation or ABI proof.
#pragma once
#include <cstddef>
using kern_return_t = int;
struct TestSemaphore;
using semaphore_t = TestSemaphore *;
constexpr semaphore_t SEMAPHORE_NULL = nullptr;
constexpr int KERN_SUCCESS = 0, KERN_INVALID_ARGUMENT = 4;
constexpr int KERN_ABORTED = 14, KERN_TERMINATED = 37, KERN_FAILURE = 5;
constexpr int SYNC_POLICY_FIFO = 0;
extern void *kernel_task;
void *IOMalloc(std::size_t);
void IOFree(void *, std::size_t);
kern_return_t semaphore_create(void *, semaphore_t *, int, int);
kern_return_t semaphore_wait(semaphore_t);
kern_return_t semaphore_signal(semaphore_t);
kern_return_t semaphore_destroy(void *, semaphore_t);
[[noreturn]] void panic(const char *, ...);
