[rice-arch-install](https://github.com/daiyam/rice-arch-install)
================================================================

## Install

```sh
git clone https://github.com/daiyam/rice-arch-install.git install
cd install
npm install
```

## Configure

- .env
- programs.yaml

## Build

```sh
npm run build
```

## Install Archlinux

```
npm run start
```


Boot the [archlinux iso](https://www.archlinux.org/download/), then in the command line, type:

```sh
curl -o- http://192.168.1.10:8000/install.sh | bash
```

License
-------

[MIT](http://www.opensource.org/licenses/mit-license.php) &copy; Baptiste Augrain