extends Node

enum Songs {
	SONG1,
	SONG2
}

## The configured functions and the input sequences to trigger
const SongInputs: Dictionary[String, Songs] = {
	"12345": Songs.SONG1,
	"15243": Songs.SONG2
}
