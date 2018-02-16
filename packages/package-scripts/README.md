# package-scripts

i'm getting tired of repeating these everywhere, so... this.

useful package scripts used by projects, mainly for deploy

[WIP]


```sh
yarn add --dev @allthings/package-scripts
```

package.json:

```
{
  ...
  "scripts": {
    ...
    "deploy": "aps deploy",
    "preversion": "aps preversion",
    "version": "aps version",
    ...
  }  
  ...
}
```
