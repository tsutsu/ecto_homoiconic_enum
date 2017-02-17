# EctoHomoiconicEnum

This is a rewrite of [`EctoEnum`](https://github.com/gjaldon/ecto_enum), with a much simpler goal.

`EctoEnum` assumes its storage is a dumb integer-typed DB field, and thus must create stable mappings between the atoms you provide it, and the integer keys they must serialize to.

`EctoHomoiconicEnum` assumes its storage is either a text-typed column, or a literal enum column with string serialization semantics (like a Postgres `ENUM`.) Such columns will both accept and return the string representations of the enum's values, so `EctoHomoiconicEnum` has no need to maintain mappings for its keys.

Instead, `EctoHomoiconicEnum` simply acts to validate that your keys are members of the values set you specify.
