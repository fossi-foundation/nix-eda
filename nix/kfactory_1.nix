{
  kfactory,
  fetchFromGitHub,
  version ? "1.14.4",
  sha256 ? "sha256-el3bGv57mAfxYG9tdLX5N6R76F+9GY9jdZaIUjMqcVU=",
}:
kfactory.overridePythonAttrs({
  inherit version;
  src = fetchFromGitHub {
    owner = "gdsfactory";
    repo = "kfactory";
    rev = "v${version}";
    inherit sha256;
  };
  
  pythonRelaxDeps = [ "typer" ]; 
})
