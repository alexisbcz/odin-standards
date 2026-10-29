/*
Package mylib is the reference skeleton for alexisbcz Odin libraries.

Rename the package, the file and every `mylib` identifier before you publish.
The procedures below exist to show the house conventions in working code:
explicit allocators, documented ownership, matching destroy procedures and
`(T, Error)` results instead of panics.

Example:
	import mylib "shared:mylib"

	main :: proc() {
		s, err := mylib.repeat("ab", 3)
		if err != nil {
			return
		}
		defer delete(s)
	}
*/
package mylib

import "base:runtime"
import "core:strings"

// Repeat_Error lists the ways repeat can fail before it allocates.
Repeat_Error :: enum {
	None,
	// The count passed to repeat was negative.
	Negative_Count,
}

/*
Error is the compound error type returned by every fallible procedure in this
package. `nil` means success. Switch on it with a type switch, or compare it
against a specific variant such as `Repeat_Error.Negative_Count`.
*/
Error :: union #shared_nil {
	Repeat_Error,
	runtime.Allocator_Error,
}

/*
repeat returns `s` concatenated `count` times.

Inputs:
- s: the string to repeat.
- count: how many copies to concatenate; must not be negative.
- allocator: allocates the result.

Returns:
- result: a new string owned by the caller; free it with `delete(result, allocator)`.
- err: `.Negative_Count` when `count < 0`, or an allocator error.
*/
repeat :: proc(s: string, count: int, allocator := context.allocator) -> (result: string, err: Error) {
	if count < 0 {
		return "", .Negative_Count
	}
	return strings.repeat(s, count, allocator)
}

/*
Tally counts how often each word occurs.

Create one with tally_init and release it with tally_destroy. A Tally stores
its own copies of the words, so the strings passed to tally_add may be freed
right after the call.
*/
Tally :: struct {
	counts:    map[string]int,
	allocator: runtime.Allocator,
}

/*
tally_init prepares `t` for use. Every allocation the tally makes, including
copies of words, uses `allocator`. Call tally_destroy when done.
*/
tally_init :: proc(t: ^Tally, allocator := context.allocator) {
	t.allocator = allocator
	t.counts = make(map[string]int, allocator)
}

// tally_destroy frees every word copy and the map itself. The tally is zeroed.
tally_destroy :: proc(t: ^Tally) {
	for word in t.counts {
		delete(word, t.allocator)
	}
	delete(t.counts)
	t^ = {}
}

// tally_add records one occurrence of `word`. It copies `word` on first sight.
tally_add :: proc(t: ^Tally, word: string) -> Error {
	if word in t.counts {
		t.counts[word] += 1
		return nil
	}
	owned := strings.clone(word, t.allocator) or_return
	t.counts[owned] = 1
	return nil
}

// tally_count returns how many times `word` was added, or 0 if never.
tally_count :: proc(t: ^Tally, word: string) -> int {
	return t.counts[word]
}
