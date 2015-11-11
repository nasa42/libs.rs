Welcome to Rust Libraries, a catalogue of Rust community's awesomeness!

<a name="propose"></a>

# Submit a change

It is really easy to contribute to Rust Libraries. Just fork [the repository](https://github.com/webstream-io/rust-libs), add your changes, and make a [pull request](https://github.com/webstream-io/rust-libs/pulls)!

Each category in Rust Libraries maps to a TOML file in [categories directory](https://github.com/webstream-io/rust-libs/tree/master/categories). Creating a new category is as easy as adding a new TOML file.

To add a new project to a category, just add `[entry.NAME]` to its TOML file (where `NAME` is same as the name used in project's `Cargo.toml`).

For example, to add [Iron](http://ironframework.io/) in [Web Frameworks](http://libs.rs/web-frameworks/) category, open [web-frameworks.toml](https://github.com/webstream-io/rust-libs/blob/master/categories/web-frameworks.toml) file and add line `[entry.iron]`. Rust Libraries will pick rest of the information from [crates.io](https://crates.io).

## Advanced options

By default Rust Libraries picks all necessary information from [crates.io](https://crates.io). But you can customise a project by supplying additional options in the TOML file.

    [entry.iron]
    
    # By default, NAME in [entry.NAME] is the crates.io ID, but you can override it here
    # or use the value `false` if your project is not on crates.io
    crates_io_id = "iron"
    
    # Name is automatically picked from crates.io, but you can override it here
    name = "Iron"
    
    # Custom homepage URL
    homepage_url = "http://ironframework.io/"
    
    # Custom repository URL
    repository_url = "https://github.com/iron/iron"


If your project needs additional options or you still have any questions, [file an issue](https://github.com/webstream-io/rust-libs/issues) and we'll take a look!

----

Licenced under [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
