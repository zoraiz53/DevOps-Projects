resource "aws_autoscaling_group" "app_asg" {
  name = "app-asg"
  max_size = 3
  min_size = 1
  desired_capacity = 1
  health_check_type = "ELB"
  health_check_grace_period = 30

  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = var.LT_id
    version = "$Latest"
  }

  target_group_arns = [
    var.ALB-TG_arn
  ]

  lifecycle {
    create_before_destroy = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      instance_warmup = 120
      min_healthy_percentage = 90
    }
  }

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name = "scale-out-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = 1
  cooldown = 60
}

resource "aws_autoscaling_policy" "scale_in" {
  name = "scale-in-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = -1
  cooldown = 60
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name = "asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  period = 60
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  statistic = "Average"
  threshold = 65
  alarm_description = "Scale out when CPU > 65%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  alarm_actions = [ aws_autoscaling_policy.scale_out.arn ]
}


resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name = "asg-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 1
  period = 60
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  statistic = "Average"
  threshold = 20
  alarm_description = "Scale in when CPU < 20%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [ aws_autoscaling_policy.scale_in.arn ]
}
 