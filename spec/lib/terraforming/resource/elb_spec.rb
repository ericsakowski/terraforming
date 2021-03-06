require "spec_helper"

module Terraforming
  module Resource
    describe ELB do
      let(:client) do
        Aws::ElasticLoadBalancing::Client.new(stub_responses: true)
      end

      let(:load_balancer_descriptions) do
        [
          {
            subnets: [
              "subnet-1234abcd",
              "subnet-5678efgh"
            ],
            canonical_hosted_zone_name_id: "12345678ABCDEF",
            canonical_hosted_zone_name: "hoge-12345678.ap-northeast-1.elb.amazonaws.com",
            listener_descriptions: [
              {
                listener: {
                  instance_port: 80,
                  ssl_certificate_id: "arn:aws:iam::123456789012:server-certificate/foobar",
                  load_balancer_port: 443,
                  protocol: "HTTPS",
                  instance_protocol: "HTTP"
                },
                policy_names: [
                  "AWSConsole-SSLNegotiationPolicy-foobar-1234567890123"
                ]
              }
            ],
            health_check: {
              healthy_threshold: 10,
              interval: 30,
              target: "HTTP:8080/status",
              timeout: 5,
              unhealthy_threshold: 2
            },
            vpc_id: "vpc-1234abcd",
            backend_server_descriptions: [],
            instances: [
              {
                instance_id: "i-1234abcd"
              }
            ],
            dns_name: "hoge-12345678.ap-northeast-1.elb.amazonaws.com",
            security_groups: [
              "sg-1234abcd",
              "sg-5678efgh"
            ],
            policies: {
              lb_cookie_stickiness_policies: [],
              app_cookie_stickiness_policies: [],
              other_policies: [
                "ELBSecurityPolicy-2014-01",
                "AWSConsole-SSLNegotiationPolicy-foobar-1234567890123"
              ]
            },
            load_balancer_name: "hoge",
            created_time: Time.parse("2014-01-01T12:12:12.000Z"),
            availability_zones: [
              "ap-northeast-1b",
              "ap-northeast-1c"
            ],
            scheme: "internet-facing",
            source_security_group: {
              owner_alias: "123456789012",
              group_name: "default"
            }
          },
          {
            subnets: [
              "subnet-9012ijkl",
              "subnet-3456mnop"
            ],
            canonical_hosted_zone_name_id: "90123456GHIJKLM",
            canonical_hosted_zone_name: "fuga-90123456.ap-northeast-1.elb.amazonaws.com",
            listener_descriptions: [
              {
                listener: {
                  instance_port: 80,
                  ssl_certificate_id: "arn:aws:iam::345678901234:server-certificate/foobar",
                  load_balancer_port: 443,
                  protocol: "HTTPS",
                  instance_protocol: "HTTP"
                },
                policy_names: [
                  "AWSConsole-SSLNegotiationPolicy-foobar-1234567890123"
                ]
              }
            ],
            health_check: {
              healthy_threshold: 10,
              interval: 30,
              target: "HTTP:8080/status",
              timeout: 5,
              unhealthy_threshold: 2
            },
            vpc_id: "",
            backend_server_descriptions: [],
            instances: [
              {
                instance_id: "i-5678efgh"
              }
            ],
            dns_name: "fuga-90123456.ap-northeast-1.elb.amazonaws.com",
            security_groups: [
              "sg-9012ijkl",
              "sg-3456mnop"
            ],
            policies: {
              lb_cookie_stickiness_policies: [],
              app_cookie_stickiness_policies: [],
              other_policies: [
                "ELBSecurityPolicy-2014-01",
                "AWSConsole-SSLNegotiationPolicy-foobar-1234567890123"
              ]
            },
            load_balancer_name: "fuga",
            created_time: Time.parse("2015-01-01T12:12:12.000Z"),
            availability_zones: [
              "ap-northeast-1b",
              "ap-northeast-1c"
            ],
            scheme: "internet-facing",
            source_security_group: {
              owner_alias: "345678901234",
              group_name: "elb"
            }
          }
        ]
      end

      let(:hoge_attributes) do
        {
          cross_zone_load_balancing: { enabled: true },
          access_log: { enabled: false },
          connection_draining: { enabled: true, timeout: 300 },
          connection_settings: { idle_timeout: 60 },
          additional_attributes: []
        }
      end

      let(:fuga_attributes) do
        {
          cross_zone_load_balancing: { enabled: true },
          access_log: { enabled: false },
          connection_draining: { enabled: true, timeout: 900 },
          connection_settings: { idle_timeout: 90 },
          additional_attributes: []
        }
      end

      before do
        client.stub_responses(:describe_load_balancers, load_balancer_descriptions: load_balancer_descriptions)
        client.stub_responses(:describe_load_balancer_attributes, [
          { load_balancer_attributes: hoge_attributes },
          { load_balancer_attributes: fuga_attributes }
        ])
      end

      describe ".tf" do
        it "should generate tf" do
          expect(described_class.tf(client: client)).to eq <<-EOS
resource "aws_elb" "hoge" {
    name                        = "hoge"
    subnets                     = ["subnet-1234abcd", "subnet-5678efgh"]
    security_groups             = ["sg-1234abcd", "sg-5678efgh"]
    instances                   = ["i-1234abcd"]
    cross_zone_load_balancing   = true
    idle_timeout                = 60
    connection_draining         = true
    connection_draining_timeout = 300

    listener {
        instance_port      = 80
        instance_protocol  = "http"
        lb_port            = 443
        lb_protocol        = "https"
        ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/foobar"
    }

    health_check {
        healthy_threshold   = 10
        unhealthy_threshold = 2
        interval            = 30
        target              = "HTTP:8080/status"
        timeout             = 5
    }
}

resource "aws_elb" "fuga" {
    name                        = "fuga"
    availability_zones          = ["ap-northeast-1b", "ap-northeast-1c"]
    security_groups             = ["sg-9012ijkl", "sg-3456mnop"]
    instances                   = ["i-5678efgh"]
    cross_zone_load_balancing   = true
    idle_timeout                = 90
    connection_draining         = true
    connection_draining_timeout = 900

    listener {
        instance_port      = 80
        instance_protocol  = "http"
        lb_port            = 443
        lb_protocol        = "https"
        ssl_certificate_id = "arn:aws:iam::345678901234:server-certificate/foobar"
    }

    health_check {
        healthy_threshold   = 10
        unhealthy_threshold = 2
        interval            = 30
        target              = "HTTP:8080/status"
        timeout             = 5
    }
}

        EOS
        end
      end

      describe ".tfstate" do
        context "without existing tfstate" do
          it "should generate tfstate" do
            expect(described_class.tfstate(client: client)).to eq JSON.pretty_generate({
              "version" => 1,
              "serial" => 1,
              "modules" => [
                {
                  "path" => [
                    "root"
                  ],
                  "outputs" => {},
                  "resources" => {
                    "aws_elb.hoge" => {
                      "type" => "aws_elb",
                      "primary" => {
                        "id" => "hoge",
                        "attributes" => {
                          "availability_zones.#" => "2",
                          "connection_draining" => "true",
                          "connection_draining_timeout" => "300",
                          "cross_zone_load_balancing" => "true",
                          "dns_name" => "hoge-12345678.ap-northeast-1.elb.amazonaws.com",
                          "health_check.#" => "1",
                          "id" => "hoge",
                          "idle_timeout" => "60",
                          "instances.#" => "1",
                          "listener.#" => "1",
                          "name" => "hoge",
                          "security_groups.#" => "2",
                          "source_security_group" => "default",
                          "subnets.#" => "2",
                        }
                      }
                    },
                    "aws_elb.fuga" => {
                      "type" => "aws_elb",
                      "primary" => {
                        "id" => "fuga",
                        "attributes" => {
                          "availability_zones.#" => "2",
                          "connection_draining" => "true",
                          "connection_draining_timeout" => "900",
                          "cross_zone_load_balancing" => "true",
                          "dns_name" => "fuga-90123456.ap-northeast-1.elb.amazonaws.com",
                          "health_check.#" => "1",
                          "id" => "fuga",
                          "idle_timeout" => "90",
                          "instances.#" => "1",
                          "listener.#" => "1",
                          "name" => "fuga",
                          "security_groups.#" => "2",
                          "source_security_group" => "elb",
                          "subnets.#" => "2",
                        }
                      }
                    }
                  }
                }
              ]
            })
          end
        end

        context "with existing tfstate" do
          it "should generate tfstate and merge it to existing tfstate" do
            expect(described_class.tfstate(client: client, tfstate_base: tfstate_fixture)).to eq JSON.pretty_generate({
              "version" => 1,
              "serial" => 89,
              "remote" => {
                "type" => "s3",
                "config" => { "bucket" => "terraforming-tfstate", "key" => "tf" }
              },
              "modules" => [
                {
                  "path" => ["root"],
                  "outputs" => {},
                  "resources" => {
                    "aws_elb.hogehoge" => {
                      "type" => "aws_elb",
                      "primary" => {
                        "id" => "hogehoge",
                        "attributes" => {
                          "availability_zones.#" => "2",
                          "connection_draining" => "true",
                          "connection_draining_timeout" => "300",
                          "cross_zone_load_balancing" => "true",
                          "dns_name" => "hoge-12345678.ap-northeast-1.elb.amazonaws.com",
                          "health_check.#" => "1",
                          "id" => "hogehoge",
                          "idle_timeout" => "60",
                          "instances.#" => "1",
                          "listener.#" => "1",
                          "name" => "hoge",
                          "security_groups.#" => "2",
                          "source_security_group" => "default",
                          "subnets.#" => "2"
                        }
                      }
                    },
                    "aws_elb.hoge" => {
                      "type" => "aws_elb",
                      "primary" => {
                        "id" => "hoge",
                        "attributes" => {
                          "availability_zones.#" => "2",
                          "connection_draining" => "true",
                          "connection_draining_timeout" => "300",
                          "cross_zone_load_balancing" => "true",
                          "dns_name" => "hoge-12345678.ap-northeast-1.elb.amazonaws.com",
                          "health_check.#" => "1",
                          "id" => "hoge",
                          "idle_timeout" => "60",
                          "instances.#" => "1",
                          "listener.#" => "1",
                          "name" => "hoge",
                          "security_groups.#" => "2",
                          "source_security_group" => "default",
                          "subnets.#" => "2",
                        }
                      }
                    },
                    "aws_elb.fuga" => {
                      "type" => "aws_elb",
                      "primary" => {
                        "id" => "fuga",
                        "attributes" => {
                          "availability_zones.#" => "2",
                          "connection_draining" => "true",
                          "connection_draining_timeout" => "900",
                          "cross_zone_load_balancing" => "true",
                          "dns_name" => "fuga-90123456.ap-northeast-1.elb.amazonaws.com",
                          "health_check.#" => "1",
                          "id" => "fuga",
                          "idle_timeout" => "90",
                          "instances.#" => "1",
                          "listener.#" => "1",
                          "name" => "fuga",
                          "security_groups.#" => "2",
                          "source_security_group" => "elb",
                          "subnets.#" => "2",
                        }
                      }
                    }
                  }
                }
              ]
            })
          end
        end
      end
    end
  end
end
