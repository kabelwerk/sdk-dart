# How to contribute

-   [Submitting bug reports](#submitting-bug-reports)
-   [Contributing code](#contributing-code)


## Submitting bug reports

If you want to report a bug you can use the repository's [issue tracker](https://github.com/kabelwerk/sdk-dart/issues) or you can contact us directly by email; the latter should be preferred if you want to report a security vulnerability.


## Contributing code

### Testing

In order to run the SDK tests, you need to set up the [Elixir](https://elixir-lang.org/) test server:

```sh
# go to the test server dir
cd sdk-dart/test/server

# install the dependencies
mix deps.get

# run the test server
mix phx.server
```

Once the test server is running on port 4000, run the tests:

```sh
# go to the repo dir
cd sdk-dart

# run the tests
dart test
```

### Example

This project also comes with a simple console app for an example. You can try out your changes in this example app and/or you can also contribute code to the example app itself. Please refer to [example/console/README.md](./example/console/README.md) for setup info.
