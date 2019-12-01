variable "key_filename" {
    type = string
}

variable "cert_filename" {
    type = string
}

variable "validity_period" {
    type = number
    default = 8760
}

variable "org" {
    type = string
}

variable "cn" {
    type = string
}

variable "location" {
    type = string
}

variable "country" {
    type = string
}

variable "ou" {
    type = string
}
