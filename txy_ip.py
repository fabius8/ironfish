import os
from tencentcloud.common import credential
from tencentcloud.common.profile.client_profile import ClientProfile
from tencentcloud.common.profile.http_profile import HttpProfile
from tencentcloud.common.exception.tencent_cloud_sdk_exception import TencentCloudSDKException
from tencentcloud.vpc.v20170312 import vpc_client, models
import json
import time
from datetime import datetime

Credential = json.load(open('credential.json'))
regions = "sa-saopaulo"

while True:
    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    for region in regions:
        try:
            # 为了保护密钥安全，建议将密钥设置在环境变量中或者配置文件中，请参考本文凭证管理章节。
            # 硬编码密钥到代码中有可能随代码泄露而暴露，有安全隐患，并不推荐。
            # cred = credential.Credential("secretId", "secretKey")
            cred = credential.Credential(Credential["secretId"], Credential["secretKey"])
            httpProfile = HttpProfile()
            httpProfile.endpoint = "vpc.tencentcloudapi.com"

            # 实例化一个client选项，可选的，没有特殊需求可以跳过
            clientProfile = ClientProfile()
            clientProfile.httpProfile = httpProfile
            # 实例化要请求产品的client对象,clientProfile是可选的
            client = vpc_client.VpcClient(cred, regions, clientProfile)

            # 实例化一个请求对象,每个接口都会对应一个request对象
            req = models.AllocateAddressesRequest()
            params = {
                "AddressCount": 1
            }
            req.from_json_string(json.dumps(params))

            # 返回的resp是一个AllocateAddressesResponse的实例，与请求对象对应
            resp = client.AllocateAddresses(req)
            # 输出json格式的字符串回包
            print(resp.to_json_string())
            
 
            
        except TencentCloudSDKException as err:
            print(err)

    time.sleep(30)