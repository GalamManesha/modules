module "dev_ec2" {
  source          = "./modules/module"
  instance_type   = "t3.micro"
  ami_id          = "ami-02b8269d5e85954ef"
  environment     = "dev"
  instance_count  = 1
}
