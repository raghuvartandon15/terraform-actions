variable "image_tag"{
    type = string
    nullable = true
}

variable "deploy_lambda"{
    type=bool
    default=false
}