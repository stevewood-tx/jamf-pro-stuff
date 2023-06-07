#!/usr/bin/python3

#########################################################################################
#
# Copyright (c) 2022, JAMF Software, LLC.  All rights reserved.
#
# THE SOFTWARE IS PROVIDED "AS-IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
# JAMF SOFTWARE, LLC OR ANY OF ITS AFFILIATES BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT, OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OF OR OTHER DEALINGS IN
# THE SOFTWARE, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# CONSEQUENTIAL OR PUNITIVE DAMAGES AND OTHER DAMAGES SUCH AS LOSS OF USE, PROFITS,
# SAVINGS, TIME OR DATA, BUSINESS INTERRUPTION, OR PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES.
#
#########################################################################################
# 
# Be sure to update the jamf_url, username, and password variables with your info
#
#########################################################################################

import base64
import requests
import sys
import json

# Set debug to True to test without a request body.  Set to False when you are ready to upload to JAWA.
debug = False

def static_variables():
    # Authentication block - consider using SYS or ENV variables here instead of hard-coding the credentials
    
    jamf_url = ""  # https://example.jamfcloud.com
    username = ""  # Jamf Pro Username
    password = ""  # Jamf Pro Password (a b64 hash of u:p works as well)
    
    return jamf_url, username, password, password, username


def dynamic_variables():
    # Check if there is a request body for JAWA.
    request_body = get_request()
    request_body = json.loads(request_body)

    # Checking for debug mode.  If debug is disabled and there is no request_body passed as an argument, the script will exit.
    if not debug:
        if not request_body:
            exit(4)
    #  IMPORTANT:
    #  Get computer_id and EA_value from JAWA request instead of hard-coding it
    computer_id = request_body.get('computer_id')
    EA_id = request_body.get('ea_id')
    EA_value = request_body.get('cache_value')

    print("***** Exiting Dynamic Variables")
    return EA_value, computer_id, EA_id


def get_request():
    try:
        request_body = sys.argv[1]
        return request_body
    except IndexError as err:
        print("No request body received.")
        return None


def get_token(jamf_url, b64_auth):
    try:
        resp = requests.post(f"{jamf_url}/api/v1/auth/token",
                             headers={'Authorization': f"Basic {b64_auth.decode()}"})
        if resp.status_code == 200:
            data = resp.json()
        else:
            print("There was an error getting a token.  Check your URL and credentials and try again.")
            exit(1)
        token = data.get('token')
        return token

    except requests.HTTPError as err:
        print("There was an error getting a token.  Check your URL and credentials and try again.")
        print(err)
        exit(1)

    except Exception as err:
        # Check your URL
        print(f"There was an error getting a token.  Check your URL and credentials and try again. \n "
              f"Error details: {err}")
        exit(2)


def main():
    jamf_url, username, password = static_variables()
    EA_value, computer_id, EA_id = dynamic_variables()
    # Encoding our secrets
    b64_auth = base64.b64encode(str.encode(f"{username}:{password}"))
    # Get a token
    token = get_token(jamf_url, b64_auth)

    # Forming the PATCH request
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "Authorization": f"Bearer {token}"
    }
    data = {
        # "id": 1,
        "extensionAttributes": [{
            "definitionId": f"{EA_id}",
            "values": [EA_value]
        }]
    }
    
    print("Data values: {}".format(data))
    print("EA Value: {}".format(EA_value))

    # sending the PATCH request
    resp = requests.patch(f"{jamf_url}/api/v1/computers-inventory-detail/{computer_id}", json=data, headers=headers)
    # Viewing response, saving as JSON
    #print(resp.status_code, resp.text)  # print the status code and response body
    print(resp.status_code)


if __name__ == '__main__':
    main()
