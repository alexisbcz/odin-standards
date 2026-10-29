// Package mylib_tests holds the unit tests for mylib. Run them with `odin test tests`.
package mylib_tests

import mylib ".."
import "core:testing"

@(test)
test_repeat_concatenates :: proc(t: ^testing.T) {
	s, err := mylib.repeat("ab", 3)
	defer delete(s)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, s, "ababab")
}

@(test)
test_repeat_zero_is_empty :: proc(t: ^testing.T) {
	s, err := mylib.repeat("ab", 0)
	defer delete(s)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, s, "")
}

@(test)
test_repeat_rejects_negative_count :: proc(t: ^testing.T) {
	_, err := mylib.repeat("ab", -1)
	testing.expect_value(t, err, mylib.Error(mylib.Repeat_Error.Negative_Count))
}

@(test)
test_tally_counts_and_owns_words :: proc(t: ^testing.T) {
	tally: mylib.Tally
	mylib.tally_init(&tally)
	defer mylib.tally_destroy(&tally)

	word, _ := mylib.repeat("go", 1)
	testing.expect_value(t, mylib.tally_add(&tally, word), nil)
	testing.expect_value(t, mylib.tally_add(&tally, word), nil)
	delete(word) // The tally keeps its own copy.

	testing.expect_value(t, mylib.tally_count(&tally, "go"), 2)
	testing.expect_value(t, mylib.tally_count(&tally, "odin"), 0)
}
