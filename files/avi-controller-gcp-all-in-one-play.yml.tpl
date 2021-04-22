---
- hosts: localhost
  connection: local
  gather_facts: no
  roles:
    - role: avinetworks.avisdk
  vars:
    avi_credentials:
        controller: ${controller_ip_1}
        username: "admin"
        password: "{{ password }}"
        api_version: ${avi_version}
    username: "admin"
    password: "{{ password }}"
    api_version: ${avi_version}
    cloud_name: "Default-Cloud"
    dns_search_domain: ${dns_search_domain}
    ansible_become: yes
    ansible_become_password: "{{ password }}"
    vpc_network_name: ${se_vpc_network_name}
    vpc_subnet_name: ${se_mgmt_subnet_name}
    vpc_project_id: ${vpc_project_id}
    region: ${region}
    se_project_id: ${se_project_id}
    se_name_prefix: ${se_name_prefix}
    se_cpu: ${se_cpu}
    se_memory: ${se_memory}
    se_disk: ${se_disk}
    se_ha_mode: ${se_ha_mode}
    vip_allocation_strategy: ${vip_allocation_strategy}
    controller_ha: ${controller_ha}
  %{ if configure_ipam_profile }
    ipam_network: ${ipam_network}  
    ipam_network_host: ${ipam_network_host}
    ipam_network_netmask: ${ipam_network_netmask}
    ipam_net_start: ${ipam_net_start}
    ipam_net_end: ${ipam_net_end}
  %{ endif }
  %{ if configure_dns_profile }
    dns_service_domain: ${dns_service_domain}
  %{ endif }
  %{ if configure_gslb }
    gslb_site_name: ${gslb_site_name}
  %{ endif }
    controller_ip_1: ${controller_ip_1}
  %{ if controller_ha }
    controller_name_1: ${controller_name_1}
    controller_name_2: ${controller_name_2}
    controller_ip_2: ${controller_ip_2}
    controller_name_3: ${controller_name_3}
    controller_ip_3: ${controller_ip_3}
  %{ endif }
  %{ if vip_allocation_strategy == "ILB" }
    cloud_router: ${cloud_router}
  %{ endif }
  tasks:
    - name: Wait for Controller to become ready
      wait_for:
        port: 443
        timeout: 600
        sleep: 5
    - name: Configure System Configurations
      avi_systemconfiguration:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        email_configuration:
          smtp_type: "SMTP_LOCAL_HOST"
          from_email: admin@avicontroller.net
        global_tenant_config:
          se_in_provider_context: true
          tenant_access_to_provider_se: true
          tenant_vrf: false
        dns_configuration:
          server_list:
          %{ for server in dns_servers }
          - addr: ${server}
            type: V4
          %{ endfor }
          search_domain: "{{ dns_search_domain }}"
        ntp_configuration:
          ntp_server_list:
            %{ for item in ntp_servers }
            - "${item.server}":
              addr: "${item.server}"
              type: ${item.type}
            %{ endfor }
        portal_configuration:
          allow_basic_authentication: false
          disable_remote_cli_shell: false
          enable_clickjacking_protection: true
          enable_http: true
          enable_https: true
          password_strength_check: true
          redirect_to_https: true
          use_uuid_from_input: false
        welcome_workflow_complete: true
        
%{ if configure_ipam_profile }
    - name: Create Avi Network Object
      avi_network:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: "network-{{ ipam_network }}"
        dhcp_enabled: false
        configured_subnets:
        - prefix:
            ip_addr:
              addr: "{{ ipam_network_host }}"
              type: V4
            mask: "{{ ipam_network_netmask }}"
          static_ip_ranges:
          - range:
              begin:
                addr: "{{ ipam_net_start }}"
                type: V4
              end:
                addr: "{{ ipam_net_end }}"
                type: V4
            type: STATIC_IPS_FOR_VIP_AND_SE
        synced_from_se: false
        ip6_autocfg_enabled: false
      register: create_network

    - name: Create Avi IPAM Profile
      avi_ipamdnsproviderprofile:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: Avi_IPAM
        type: IPAMDNS_TYPE_INTERNAL
        internal_profile:
          ttl: 30
          usable_networks:
          - nw_ref: "{{ create_network.obj.url }}"
        allocate_ip_in_vrf: false
      register: create_ipam
%{ endif }
%{ if configure_dns_profile }
    - name: Create Avi DNS Profile
      avi_ipamdnsproviderprofile:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: Avi_DNS
        type: IPAMDNS_TYPE_INTERNAL_DNS
        internal_profile:
          dns_service_domain:
          - domain_name: "{{ dns_service_domain }}"
            pass_through: true
          ttl: 30
      register: create_dns
%{ endif }
    - name: Configure Cloud
      avi_cloud:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: "{{ cloud_name }}"
        vtype: CLOUD_GCP
        dhcp_enabled: true
        license_type: "LIC_CORES" 
        %{ if configure_ipam_profile }
        ipam_provider_ref: "{{ create_ipam.obj.url }}" %{ endif}
        %{ if configure_dns_profile }
        dns_provider_ref:  "{{ create_dns.obj.url }}" %{ endif}
        gcp_configuration:
          region_name: "{{ region }}"
          se_project_id: "{{ se_project_id }}"
          zones: %{ for zone in zones }
            - "${zone}"
            %{ endfor }
          network_config:
            config:  "INBAND_MANAGEMENT"
            inband:
              vpc_subnet_name: "{{ vpc_subnet_name }}"
              vpc_project_id: "{{ vpc_project_id }}"
              vpc_network_name: "{{ vpc_network_name }}"
          firewall_target_tags:
            - "avi-se"
          dhcp_enabled: false
          vip_allocation_strategy:
            mode: "{{ vip_allocation_strategy }}" %{ if vip_allocation_strategy == "ILB" }
            ilb:
              cloud_router_names:
                - "{{ cloud_router }}"
            %{ endif }
      register: avi_cloud
    - name: Set Backup Passphrase
      avi_backupconfiguration:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        name: Backup-Configuration
        backup_passphrase: "{{ password }}"
        upload_to_remote_host: false
%{ if se_ha_mode == "active/active" }
    - name: Configure SE-Group
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "serviceenginegroup"
        tenant: "admin"
        data:
          name: "Default-Group" 
          avi_credentials: "{{ avi_credentials }}"
          state: present
          cloud_ref: "{{ avi_cloud.obj.url }}"
          ha_mode: HA_MODE_SHARED_PAIR
          min_scaleout_per_vs: 2
          algo: PLACEMENT_ALGO_DISTRIBUTED
          buffer_se: "0"
          max_se: "10"
          se_name_prefix: "{{ se_name_prefix }}"
          vcpus_per_se: "{{ se_cpu }}"
          memory_per_se: "{{ se_memory * 1024 }}"
          disk_per_se: "{{ se_disk }}"
          realtime_se_metrics:
            duration: "10080"
            enabled: true
%{ endif }
%{ if se_ha_mode == "n+m" }
    - name: Configure SE-Group
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "serviceenginegroup"
        tenant: "admin"
        data:
          name: "Default-Group" 
          avi_credentials: "{{ avi_credentials }}"
          state: present
          cloud_ref: "{{ avi_cloud.obj.url }}"
          ha_mode: HA_MODE_SHARED
          min_scaleout_per_vs: 1
          algo: PLACEMENT_ALGO_PACKED
          buffer_se: "1"
          max_se: "10"
          se_name_prefix: "{{ se_name_prefix }}"
          vcpus_per_se: "{{ se_cpu }}"
          memory_per_se: "{{ se_memory * 1024 }}"
          disk_per_se: "{{ se_disk }}"
          realtime_se_metrics:
            duration: "10080"
            enabled: true
%{ endif }
%{ if se_ha_mode == "active/standby" }
    - name: Configure SE-Group
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "serviceenginegroup"
        tenant: "admin"
        data:
          name: "Default-Group" 
          avi_credentials: "{{ avi_credentials }}"
          state: present
          cloud_ref: "{{ avi_cloud.obj.url }}"
          ha_mode: HA_MODE_LEGACY_ACTIVE_STANDBY
          min_scaleout_per_vs: 1
          buffer_se: "0"
          max_se: "2"
          se_name_prefix: "{{ se_name_prefix }}"
          vcpus_per_se: "{{ se_cpu }}"
          memory_per_se: "{{ se_memory * 1024 }}"
          disk_per_se: "{{ se_disk }}"
          realtime_se_metrics:
            duration: "10080"
            enabled: true
%{ endif }
%{ if configure_gslb }
    - name: Configure GSLB SE-Group
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "serviceenginegroup"
        tenant: "admin"
        data:
          name: "g-dns" 
          cloud_ref: "{{ avi_cloud.obj.url }}"
          ha_mode: HA_MODE_SHARED
          algo: PLACEMENT_ALGO_PACKED
          buffer_se: "1"
          max_se: "4"
          max_vs_per_se: "2"
          extra_shared_config_memory: 2000
          se_name_prefix: "{{ se_name_prefix }}"
          realtime_se_metrics:
            duration: "10080"
            enabled: true
      register: gslb_se_group
%{ endif}
%{ if configure_dns_vs }
    - name: Create DNS VSVIP
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "vsvip"
        tenant: "admin"
        data:
          east_west_placement: false
          cloud_ref: "{{ avi_cloud.obj.url }}"
          %{ if configure_gslb }
          se_group_ref: "{{ gslb_se_group.obj.url }}"
          %{ endif}
          vip:
          - enabled: true
            auto_allocate_ip: true
            %{ if controller_public_address }
            auto_allocate_floating_ip: true
            %{ else }
            auto_allocate_floating_ip: false
            %{ endif }
            avi_allocated_vip: false
            avi_allocated_fip: false
            auto_allocate_ip_type: V4_ONLY
            prefix_length: 32
            placement_networks: []
            ipam_network_subnet:
              network_ref: "{{ create_network.obj.url }}"
              subnet:
                ip_addr:
                  addr: "{{ ipam_network_host }}"
                  type: V4
                mask: "{{ ipam_network_netmask }}"
          dns_info:
          - type: DNS_RECORD_A
            algorithm: DNS_RECORD_RESPONSE_CONSISTENT_HASH
            fqdn: "dns-vs.{{ dns_service_domain }}"
          name: vsvip-DNS-VS-Default-Cloud
      register: vsvip_results

    - name: Display DNS VS VIP
      ansible.builtin.debug:
        var: vsvip_results

    - name: Create DNS Virtual Service
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: "virtualservice"
        tenant: "admin"
        data:
          name: DNS-VS
          enabled: true
          analytics_policy:
            full_client_logs:
              enabled: true
              duration: 30
              throttle: 10
            client_insights: NO_INSIGHTS
            all_headers: false
            metrics_realtime_update:
              enabled: true
              duration: 30
            udf_log_throttle: 10
            significant_log_throttle: 10
            learning_log_policy:
              enabled: false
            client_log_filters: []
            client_insights_sampling: {}
          enable_autogw: true
          weight: 1
          delay_fairness: false
          max_cps_per_client: 0
          limit_doser: false
          type: VS_TYPE_NORMAL
          cloud_type: CLOUD_GCP
          use_bridge_ip_as_vip: false
          flow_dist: LOAD_AWARE
          ign_pool_net_reach: false
          ssl_sess_cache_avg_size: 1024
          remove_listening_port_on_vs_down: false
          close_client_conn_on_config_update: false
          bulk_sync_kvcache: false
          advertise_down_vs: false
          scaleout_ecmp: false
          active_standby_se_tag: ACTIVE_STANDBY_SE_1
          flow_label_type: NO_LABEL
          content_rewrite:
            request_rewrite_enabled: false
            response_rewrite_enabled: false
            rewritable_content_ref: /api/stringgroup?name=System-Rewritable-Content-Types
          sideband_profile:
            sideband_max_request_body_size: 1024
          use_vip_as_snat: false
          traffic_enabled: true
          allow_invalid_client_cert: false
          vh_type: VS_TYPE_VH_SNI
          application_profile_ref: /api/applicationprofile?name=System-DNS
          network_profile_ref: /api/networkprofile?name=System-UDP-Per-Pkt
          analytics_profile_ref: /api/analyticsprofile?name=System-Analytics-Profile
          %{ if configure_gslb }
          se_group_ref: "{{ gslb_se_group.obj.url }}"
          %{ endif}
          cloud_ref: "{{ avi_cloud.obj.url }}"
          services:
          - port: 53
            port_range_end: 53
            enable_ssl: false
            enable_http2: false
          #dns_policies:
          #- index: 11
          #  dns_policy_ref_data:
          #    rule: []
          #    name: DNS-VIP-Default-Cloud-DNS-Policy-0
          #topology_policies:
          #- index: 11
          #  dns_policy_ref_data:
          #    rule: []
          #    name: DNS-VIP-Default-Cloud-Topology-Policy-0
          vsvip_ref: "{{ vsvip_results.obj.url }}"
          vs_datascripts: []
      register: dns_vs

    - name: Add DNS-VS to System Configuration
      avi_systemconfiguration:
        avi_credentials: "{{ avi_credentials }}"
        avi_api_update_method: patch
        avi_api_patch_op: add
        tenant: admin
        dns_virtualservice_refs: "{{ dns_vs.obj.url }}"
%{ endif}
%{ if configure_gslb }
    - name: GSLB Config | Verify Cluster UUID
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: get
        path: cluster
      register: cluster
    - name: Create GSLB Config
      avi_gslb:
        avi_credentials: "{{ avi_credentials }}"
        name: "GSLB"
        sites:
          - name: "{{ gslb_site_name }}"
            username: "{{ username }}"
            password: "{{ password }}"
            ip_addresses:
              - type: "V4"
                addr: "{{ controller_ip_1 }}"
            enabled: True
            member_type: "GSLB_ACTIVE_MEMBER"
            port: 443
            dns_vses:
              - dns_vs_uuid: "{{ dns_vs.obj.uuid }}"
            cluster_uuid: "{{ cluster.obj.uuid }}"
        dns_configs:
          %{ for domain in gslb_domains }
          - domain_name: "${domain}"
          %{ endfor }
        leader_cluster_uuid: "{{ cluster.obj.uuid }}"
      register: gslb_results
  %{ endif }
  %{ if configure_gslb_additional_sites }%{ for site in additional_gslb_sites }

    - name: GSLB Config | Verify DNS configuration
      avi_api_session:
        controller: "${site.ip_address}"
        username: "admin"
        password: "{{ password }}"
        api_version: ${avi_version}
        http_method: get
        path: virtualservice?name=DNS-VS
      register: dns_vs_verify

    - name: Display DNS VS Verify
      ansible.builtin.debug:
        var: dns_vs_verify

    - name: GSLB Config | Verify GSLB site configuration
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: post
        path: gslbsiteops/verify
        data:
          name: name
          username: admin
          password: "{{ password }}"
          port: 443
          ip_addresses:
            - type: "V4"
              addr: "${site.ip_address}"
      register: gslb_verify
      
    - name: Display GSLB Siteops Verify
      ansible.builtin.debug:
        var: gslb_verify

    - name: Add GSLB Sites
      avi_api_session:
        avi_credentials: "{{ avi_credentials }}"
        http_method: patch
        path: "gslb/{{ gslb_results.obj.uuid }}"
        tenant: "admin"
        data:
          add:
            sites:
              - name: "${site.name}"
                member_type: "GSLB_ACTIVE_MEMBER"
                username: "{{ username }}"
                password: "{{ password }}"
                cluster_uuid: "{{ gslb_verify.obj.rx_uuid }}"
                ip_addresses:
                  - type: "V4"
                    addr: "${site.ip_address}"
                dns_vses:
                  - dns_vs_uuid: "{{ dns_vs_verify.obj.results.0.uuid }}"
  %{ endfor }%{ endif }
%{ if controller_ha }
    - name: Controller Cluster Configuration
      avi_cluster:
        avi_credentials: "{{ avi_credentials }}"
        state: present
        #virtual_ip:
        #  type: V4
        #  addr: "{{ controller_cluster_vip }}"
        nodes:
            - name: "{{ controller_name_1 }}" 
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip_1 }}"
            - name: "{{ controller_name_2 }}"
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip_2 }}"
            - name: "{{ controller_name_3 }}"
              password: "{{ password }}"
              ip:
                type: V4
                addr: "{{ controller_ip_3 }}"
        name: "cluster01"
        tenant_uuid: "admin"
%{ endif }