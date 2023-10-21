resource "aws_glue_catalog_database" "main" {
  name = local.project_name
}

resource "aws_glue_catalog_table" "main" {
  name          = "cloudtrail"
  database_name = aws_glue_catalog_database.main.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                             = "TRUE"
    "parquet.compression"                = "SNAPPY"
    "projection.enabled"                 = "true"
    "projection.account_id.type"         = "injected"
    "projection.region.type"             = "injected"
    "projection.timestamp.format"        = "yyyy/MM/dd"
    "projection.timestamp.interval"      = "1"
    "projection.timestamp.interval.unit" = "DAYS"
    "projection.timestamp.range"         = "2020/01/01,NOW"
    "projection.timestamp.type"          = "date"
    "storage.location.template"          = "s3://${var.cloudtrail_bucket}/AWSLogs/${data.aws_organizations_organization.this.id}/$${account_id}/CloudTrail/$${region}/$${timestamp}/"
  }

  partition_keys {
    name = "account_id"
    type = "string"
  }

  partition_keys {
    name = "region"
    type = "string"
  }

  partition_keys {
    name = "timestamp"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${var.cloudtrail_bucket}/AWSLogs/${data.aws_organizations_organization.this.id}/"
    input_format  = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "cloudtrail-stream"
      serialization_library = "org.apache.hive.hcatalog.data.JsonSerDe"
    }

    columns {
      name = "eventversion"
      type = "STRING"
    }

    columns {
      name = "useridentity"
      # type = "STRUCT<type: STRING, principalid: STRING, arn: STRING, accountid: STRING, invokedby: STRING, accesskeyid: STRING, username: STRING, sessioncontext: STRUCT<attributes: STRUCT<mfaauthenticated: STRING, creationdate: STRING>, sessionissuer: STRUCT<type: STRING, principalid: STRING, arn: STRING, accountid: STRING, username: STRING>, ec2roledelivery:string, webidfederationdata:map<string,string>>>"
      type = "struct<type:string,principalId:string,arn:string,accountId:string,invokedBy:string,accessKeyId:string,userName:string,sessionContext:struct<attributes:struct<mfaAuthenticated:string,creationDate:string>,sessionIssuer:struct<type:string,principalId:string,arn:string,accountId:string,username:string>,ec2RoleDelivery:string,webIdFederationData:map<string,string>>>"
    }

    columns {
      name = "eventtime"
      type = "STRING"
    }

    columns {
      name = "eventsource"
      type = "STRING"
    }

    columns {
      name = "eventname"
      type = "STRING"
    }

    columns {
      name = "awsregion"
      type = "STRING"
    }

    columns {
      name = "sourceipaddress"
      type = "STRING"
    }

    columns {
      name = "useragent"
      type = "STRING"
    }

    columns {
      name = "errorcode"
      type = "STRING"
    }

    columns {
      name = "errormessage"
      type = "STRING"
    }

    columns {
      name = "requestparameters"
      type = "STRING"
    }

    columns {
      name = "responseelements"
      type = "STRING"
    }

    columns {
      name = "additionaleventdata"
      type = "STRING"
    }

    columns {
      name = "requestid"
      type = "STRING"
    }

    columns {
      name = "eventid"
      type = "STRING"
    }

    columns {
      name = "readonly"
      type = "STRING"
    }

    columns {
      name = "resources"
      #      type = "ARRAY<STRUCT<arn: STRING, accountid: STRING, type: STRING>>"
      type = "array<struct<arn:string,accountId:string,type:string>>"
    }

    columns {
      name = "eventtype"
      type = "STRING"
    }

    columns {
      name = "apiversion"
      type = "STRING"
    }

    columns {
      name = "recipientaccountid"
      type = "STRING"
    }

    columns {
      name = "serviceeventdetails"
      type = "STRING"
    }

    columns {
      name = "sharedeventid"
      type = "STRING"
    }

    columns {
      name = "vpcendpointid"
      type = "STRING"
    }

    columns {
      name = "tlsdetails"
      type = "struct<tlsversion:string, ciphersuite:string, clientprovidedhostheader:string>"
    }
  }
}
