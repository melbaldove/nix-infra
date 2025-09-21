{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nginx.nix
    ../../modules/shared/core.nix
    ../../modules/shared/ssh-keys.nix
    ../../modules/shared/promtail.nix
    ../../modules/linux/default.nix
    ../../modules/linux/agenix.nix
    ../../modules/infrastructure/restic-backup.nix
    # TODO: These will be imported from nextdesk-services
    # ../../modules/system/linux/twenty-crm.nix
    # ../../modules/system/linux/ghost-cms.nix
    # ../../modules/system/linux/outline.nix
    ../../modules/shared/node-exporter.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "newton";
  networking.extraHosts = ''
    172.236.148.68 shannon
    10.0.0.2 einstein
  '';

  # WireGuard VPN client configuration
  age.secrets.wireguard-newton-private.file = ../../secrets/infrastructure/wireguard-newton-private.age;

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.1.2/24" ];
      privateKeyFile = config.age.secrets.wireguard-newton-private.path;

      peers = [
        {
          # Shannon VPN server (startup interface)
          publicKey = "VyeqpVLFr+62pyzKUI4Dq/WZXS5pZR/Ps2Yx3aNKgm0=";
          allowedIPs = [ "10.0.1.0/24" ];
          endpoint = "shannon:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  # Node exporter configuration
  monitoring.nodeExporter.listenAddress = "10.0.1.2";

  # cAdvisor for Docker container metrics
  services.cadvisor = {
    enable = true;
    port = 9200;
    listenAddress = "10.0.1.2";
  };

  # Allow VPN traffic to monitoring ports
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9100 9200 9080 ];


  # Override Promtail client to use Shannon's startup network IP
  services.promtail.configuration.clients = lib.mkForce [
    {
      url = "http://10.0.1.1:3100/loki/api/v1/push";
    }
  ];

  # Newton-specific Promtail configuration for Docker logs
  services.promtail.configuration.scrape_configs = lib.mkAfter [
    {
      job_name = "docker-containers";
      docker_sd_configs = [
        {
          host = "unix:///var/run/docker.sock";
          refresh_interval = "5s";
          # Collect logs from all containers, not just those with specific labels
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__meta_docker_container_name" ];
          regex = "/(.*)";
          target_label = "container";
          replacement = "\${1}";
        }
        {
          source_labels = [ "__meta_docker_container_log_stream" ];
          target_label = "stream";
        }
        {
          source_labels = [ "__meta_docker_container_label_com_docker_compose_service" ];
          target_label = "compose_service";
        }
        {
          source_labels = [ "__meta_docker_container_label_com_docker_compose_project" ];
          target_label = "compose_project";
        }
        {
          source_labels = [ "__meta_docker_container_image" ];
          target_label = "image";
        }
      ];
      pipeline_stages = [
        {
          docker = {};
        }
        {
          timestamp = {
            source = "timestamp";
            format = "RFC3339Nano";
          };
        }
      ];
    }
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Mount Hetzner volume for backups
  fileSystems."/var/lib/restic-backups" = {
    device = "/dev/sdb";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # Create backup directories with proper ownership
  systemd.tmpfiles.rules = [
    "d /var/lib/restic-backups/newton-restic 0755 root root -"
  ];


  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    arion
    docker-compose
    bun
    google-chrome
  ];

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };


  # Grant promtail access to Docker socket for container log collection
  users.users.promtail.extraGroups = [ "docker" ];

  # Configure agenix secrets for backup
  age.secrets.restic-password.file = ../../secrets/infrastructure/restic-password.age;
  
  # Configure n8n secrets
  # TODO: n8n secrets will come from nextdesk-services
  # age.secrets.n8n-encryption-key.file = ../../secrets/n8n-encryption-key.age;
  # age.secrets.n8n-db-password.file = ../../secrets/n8n-db-password.age;
  # age.secrets.n8n-basic-auth-password.file = ../../secrets/n8n-basic-auth-password.age;

  # Configure restic backup service
  services.restic-backup = {
    enable = true;
    repository = "/var/lib/restic-backups/newton-restic";
    passwordFile = config.age.secrets.restic-password.path;
    paths = [
      "/var/lib/docker/volumes/ghost_ghost-content"
      "/var/lib/docker/volumes/ghost_db-data"
      "/var/lib/docker/volumes/twenty_db-data"
      "/var/lib/docker/volumes/twenty_server-local-data"
      "/var/lib/docker/volumes/outline_outline-data"
    ];
  };

  # Configure Twenty CRM service
  services.twenty-crm = {
    enable = true;
    serverUrl = "https://crm.workwithnextdesk.com";
    port = 3000;
    
    database = {
      user = "postgres";
      passwordFile = config.age.secrets.twenty-db-password.path;
    };
    
    appSecretFile = config.age.secrets.twenty-app-secret.path;
    
    auth.google = {
      enabled = true;
      clientIdFile = config.age.secrets.twenty-google-client-id.path;
      clientSecretFile = config.age.secrets.twenty-google-client-secret.path;
      callbackUrl = "https://crm.workwithnextdesk.com/auth/google/redirect";
      apisCallbackUrl = "https://crm.workwithnextdesk.com/auth/google-apis/get-access-token";
    };
    auth.microsoft.enabled = false;
    messagingProviderGmailEnabled = true;
    calendarProviderGoogleEnabled = true;
    email = {
      driver = "smtp";
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        secure = true;
        user = "melbourne@workwithnextdesk.com";
        passwordFile = config.age.secrets.twenty-smtp-password.path;
        from = "noreply@workwithnextdesk.com";
      };
    };
  };

  # Configure Ghost CMS service
  services.ghost-cms = {
    enable = true;
    url = "https://cms.workwithnextdesk.com";
    port = 8080;
    
    database = {
      client = "mysql";
      host = "db";
      user = "root";
      database = "ghost";
      passwordFile = config.age.secrets.ghost-db-password.path;
    };
    
    mail = {
      transport = "SMTP";
      from = "NextDesk <noreply@workwithnextdesk.com>";
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        secure = false;  # Use STARTTLS
        user = "melbourne@workwithnextdesk.com";
        passwordFile = config.age.secrets.ghost-smtp-password.path;
      };
    };
    
    nodeEnv = "production";
  };

  # Configure Outline Wiki service
  services.outline-wiki = {
    enable = true;
    url = "https://wiki.workwithnextdesk.com";
    port = 3001;
    
    secretKeyFile = config.age.secrets.outline-secret-key.path;
    utilsSecretFile = config.age.secrets.outline-utils-secret.path;
    
    database = {
      host = "twenty-db-1";
      port = 5432;
      user = "postgres";
      passwordFile = config.age.secrets.outline-db-password.path;
      database = "outline";
    };
    
    redis = {
      host = "twenty-redis-1";
      port = 6379;
    };
    
    auth.google = {
      enabled = true;
      clientIdFile = config.age.secrets.outline-google-client-id.path;
      clientSecretFile = config.age.secrets.outline-google-client-secret.path;
    };
    
    smtp = {
      enabled = true;
      host = "smtp.gmail.com";
      port = 587;
      user = "melbourne@workwithnextdesk.com";
      passwordFile = config.age.secrets.outline-smtp-password.path;
      fromEmail = "noreply@workwithnextdesk.com";
      replyEmail = "noreply@workwithnextdesk.com";
    };
    
    slack = {
      enabled = true;
      appId = "A0W3UMKBQ";
      messageActions = true;
    };
  };

  # Configure n8n service using built-in NixOS module
  services.n8n = {
    enable = true;
    openFirewall = false; # We use nginx proxy
    webhookUrl = "https://n8n.workwithnextdesk.com";
  };

  # Ensure n8n database exists
  systemd.services.n8n-db-init = {
    description = "Initialize n8n database";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "n8n.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for PostgreSQL container to be ready
      until ${pkgs.docker}/bin/docker exec twenty-db-1 pg_isready -U postgres; do
        echo "Waiting for PostgreSQL to be ready..."
        sleep 2
      done
      
      # Create n8n database if it doesn't exist
      ${pkgs.docker}/bin/docker exec twenty-db-1 psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'n8n'" | grep -q 1 || \
      ${pkgs.docker}/bin/docker exec twenty-db-1 psql -U postgres -c "CREATE DATABASE n8n;"
    '';
  };

  # Service to create n8n environment file
  systemd.services.n8n-env-setup = {
    description = "Create n8n environment file";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      LoadCredential = [
        "n8n-db-password:${config.age.secrets.n8n-db-password.path}"
      ];
    };
    script = ''
      echo "DB_POSTGRESDB_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/n8n-db-password)" > /tmp/n8n-env
    '';
  };

  # Configure n8n service with database dependency
  systemd.services.n8n = {
    after = [ "n8n-db-init.service" "n8n-env-setup.service" ];
    requires = [ "n8n-db-init.service" "n8n-env-setup.service" ];
    environment = {
      # Database configuration
      DB_TYPE = "postgresdb";
      DB_POSTGRESDB_HOST = "localhost";
      DB_POSTGRESDB_PORT = "5432";
      DB_POSTGRESDB_DATABASE = "n8n";
      DB_POSTGRESDB_USER = "postgres";
      
      # Basic authentication disabled - using nginx auth instead
      N8N_BASIC_AUTH_ACTIVE = "false";
      
      # Network configuration
      N8N_HOST = "0.0.0.0";
      N8N_PORT = "5678";
      
      # Other settings
      N8N_DIAGNOSTICS_ENABLED = "false";
      N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
      GENERIC_TIMEZONE = "Etc/UTC";
      TZ = "Etc/UTC";
      
      # Puppeteer configuration - use system Chrome
      PUPPETEER_SKIP_DOWNLOAD = "true";
      PUPPETEER_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome-stable";
      
    };
    preStart = ''
      # Create writable copy of pulse in working directory
      rm -rf pulse
      cp -r ${inputs.pulse} pulse
      chmod -R u+w pulse
      
      # Install pulse dependencies
      cd pulse
      ${pkgs.bun}/bin/bun install
      
      # Chrome is provided by system packages, no need to install
      cd ..
      
      # Run database migrations for pulse database
      export PGPASSWORD="$(cat $CREDENTIALS_DIRECTORY/n8n-db-password)"
      
      # Create pulse database and user if they don't exist
      ${pkgs.postgresql_15}/bin/psql -h localhost -U postgres <<EOF || true
        SELECT 'CREATE DATABASE pulse' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'pulse')\\gexec
        DO \$\$
        BEGIN
          IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'pulse') THEN
            CREATE USER pulse WITH PASSWORD '$(cat $CREDENTIALS_DIRECTORY/n8n-db-password)';
          END IF;
        END
        \$\$;
        GRANT ALL PRIVILEGES ON DATABASE pulse TO pulse;
        \\c pulse
        GRANT CREATE ON SCHEMA public TO pulse;
        GRANT ALL ON SCHEMA public TO pulse;
EOF
      
      # Run migrations on pulse database
      cd pulse/migrations
      for migration in $(ls *.up.sql | sort); do
        echo "Running migration: $migration"
        ${pkgs.postgresql_15}/bin/psql -h localhost -U pulse -d pulse -f "$migration" || true
      done
    '';
    serviceConfig = {
      # Use the environment file created by n8n-env-setup service
      EnvironmentFile = "/tmp/n8n-env";
      WorkingDirectory = "/var/lib/private/n8n";
    };
    path = with pkgs; [ bun google-chrome ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = import "${inputs.dotfiles}/users/melbournebaldove/core.nix";
  };

  system.stateVersion = "24.11";
}