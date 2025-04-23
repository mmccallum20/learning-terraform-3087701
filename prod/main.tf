module "prod" {
    source = "../modules/blog"

    environment = {
        name = "prod"
        network_prefix = "10.2"
    }

    min_size = 1
    max_size = 2
}