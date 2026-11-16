{ lib, pkgs, ... }:
let
  yaml = pkgs.formats.yaml { };
  contexts = {
    dev = {
      name = "dev";
      description = "Dev";
      environment = "dev";
      aws = {
        profile = "commpla-dev";
        region = "eu-west-1";
      };
      kubernetes = {
        context = "arn:aws:eks:eu-west-1:907383592745:cluster/commpla-dev";
        namespace = "burstable";
      };
    };
    prod = {
      name = "prod";
      description = "Prod";
      environment = "prod";
      aws = {
        profile = "commpla-prod";
        region = "eu-west-1";
      };
      kubernetes = {
        context = "arn:aws:eks:eu-west-1:510706730724:cluster/commpla-prod";
        namespace = "burstable";
      };
    };
  };
in {
  xdg.configFile = lib.mapAttrs' (name: ctx:
    lib.nameValuePair "ctx/contexts/${name}.yaml" {
      source = yaml.generate "${name}.yaml" ctx;
    }
  ) contexts;
}
