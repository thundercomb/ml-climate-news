variable "project" {
  type = string
}

variable "billing_account" {
  type = string
}

variable "owner_email" {
  type = string
}

variable "region" {
  type = string
}

variable "repos" {
  type = set(string)
}

variable "topics" {
  type = set(string)
}

variable "subscriptions" {
  type = set(string)
}

variable "datasets" {
  type = set(string)
}

variable "ml_models_bucket" {
  type = string
}
