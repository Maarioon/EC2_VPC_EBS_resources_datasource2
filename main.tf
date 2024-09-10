
  
data "aws_vpc" "c7_default_vpc" {  
  id = "vpc-0fb1ff831f6f054ba"    
}  

  
data "aws_subnet" "public_subnet" {  
  id = "subnet-04b466912390451c8"   
}  

data "aws_security_group" "default" {
  id = "sg-05693bfaf96f0fa6f"
}

data "aws_key_pair" "busola_tf-keypair" {
  key_name           = "busolaaaa"
  include_public_key = true
}

resource "aws_instance" "busola_tf" {
  ami             = "ami-0e86e20dae9224db8"
  instance_type   = "t2.micro"
  subnet_id       = data.aws_subnet.public_subnet.id
  security_groups = [data.aws_security_group.default.id]
  key_name        = "busolaaaa"
}

resource "aws_ebs_volume" "busola_tf_ebs_v" {
  availability_zone = aws_instance.busola_tf.availability_zone
  size              = 10  
  type              = "gp2"  
  tags = {
    Name = "busola_tf-ebs-volume"
  }
}


resource "aws_volume_attachment" "busola_tf" {
  device_name = "/dev/sdh" 
  volume_id   = aws_ebs_volume.busola_tf_ebs_v.id  
  instance_id = aws_instance.busola_tf.id
}
