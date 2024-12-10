variable "subscription_id" {
    type = string
    default = "54828624-9e2e-4348-b537-8d2c7473541b"
}

variable "rg_name" {
    type = string
    default = "RG4"
}

variable "location" {
    type = string
    default = "westeurope"
}

variable "vnet_name" {
    type = string
    default = "myVNet"
}

variable "vnet_network" {
    type = string
    default = "10.21.0.0/16"
}

variable "subnet_be_name" {
    type = string
    default = "myBackendSubnet"
}

variable "subnet_be_network" {
    type = string
    default = "10.21.1.0/24"
}

variable "subnet_fe_name" {
    type = string
    default = "myAGSubnet"
}

variable "subnet_fe_network" {
    type = string
    default = "10.21.0.0/24"
}

variable "public_ip_name" {
    type = string
    default = "myAGPublicIPAddress"
}
