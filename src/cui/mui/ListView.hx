package cui.mui;


/**
	`cui`'s conformance for `mui.ui.ListView`.

	`mui` resolves this by name through `mui.Contract` and `mui.macros.Bind`,
	which is why nothing in `mui` mentions `cui`. Moved here, unchanged, from the
	`#if (mui_backend == "cui")` branch it used to live in.
**/
typedef ListView = cui.ui.ListView;
