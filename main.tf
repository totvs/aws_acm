resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain_name
  validation_method = var.validation_method

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "hz" {
  name         = var.zone_domain_name
  private_zone = false
}

resource "aws_route53_record" "record" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      zone_id = dvo.domain_name == var.zone_domain_name ? data.aws_route53_zone.hz.zone_id : data.aws_route53_zone.hz.zone_id

    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hz.zone_id
}

data "aws_route53_zone" "hz_private" {
  name         = var.zone_domain_name_private
  private_zone = true
}

resource "aws_route53_record" "record_private" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      zone_id = dvo.domain_name == var.zone_domain_name ? data.aws_route53_zone.hz_private.zone_id : data.aws_route53_zone.hz_private.zone_id

    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hz_private.zone_id
}

resource "aws_acm_certificate_validation" "certificate-validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.record : record.fqdn]
}
