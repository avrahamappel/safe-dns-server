{
  description = "A DNS server container that proxies to OpenDNS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      upstreamDns = [
        "208.67.222.222"
        "208.67.220.220"
      ];

      cnames = {
        # Google
        "www.google.com" = "forcesafesearch.google.com";
        "www.google.ca" = "forcesafesearch.google.com";

        # YouTube
        "www.youtube.com" = "restrict.youtube.com";
        "m.youtube.com" = "restrict.youtube.com";
        "youtubei.googleapis.com" = "restrict.youtube.com";
        "youtube.googleapis.com" = "restrict.youtube.com";
        "www.youtube-nocookie.com" = "restrict.youtube.com";

        # DuckDuckGo
        "duckduckgo.com" = "safe.duckduckgo.com";
      };

      lines = strs: builtins.concatStringsSep "\n" strs;

      dnsmasqConf = pkgs.writeText "dnsmasq.conf" ''
        ${lines (map (s: "server ${s}") upstreamDns)}
        ${lines (builtins.attrValues (builtins.mapAttrs (from: to: "cname ${from} ${to}") cnames))}
      '';
    in
    {
      packages.default = pkgs.dockerTools.buildImage {
        name = "home-dns";

        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = [ pkgs.dnsmasq ];
          pathsToLink = [ "/bin" ];
        };

        config = {
          Cmd = [ "dnsmasq" "-C" dnsmasqConf ];
        };
      };
    });
}
