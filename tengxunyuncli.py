import os
from tencentcloud.common import credential
from tencentcloud.common.exception.tencent_cloud_sdk_exception import TencentCloudSDKException
from tencentcloud.cvm.v20170312 import cvm_client, models
import json
import time
from datetime import datetime

Credential = json.load(open('credential.json'))

while True:
    try:
        print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        # 为了保护密钥安全，建议将密钥设置在环境变量中或者配置文件中，请参考本文凭证管理章节。
        # 硬编码密钥到代码中有可能随代码泄露而暴露，有安全隐患，并不推荐。
        # cred = credential.Credential("secretId", "secretKey")
        cred = credential.Credential(Credential["secretId"], Credential["secretKey"])
        client = cvm_client.CvmClient(cred, "ap-singapore")

        req = models.DescribeInstancesRequest()
        req.Limit = 100
        resp = client.DescribeInstances(req)
        #print(resp.to_json_string())
        
        returnList = []
        print("获取每个机器状态...")
        for i in resp.InstanceSet:
            print(i.InstanceId, i.InstanceState)
            if i.InstanceState == "STOPPED":
                returnList.append(i.InstanceId)

        
        #print(returnList)
        if returnList:
            req = models.TerminateInstancesRequest()
            print("销毁机器...", returnList)
            req.InstanceIds = returnList
            resp = client.TerminateInstances(req)
            print(resp)
        
    except TencentCloudSDKException as err:
        print(err)

    time.sleep(30)