# Salesforce VeChain ToolChain Connectors

Demo connector build to enable Salesforce CRM to retrieve data stored on VeChain public blockchain (https://www.vechain.org/) from the ToolChain BaaS (https://www.vetoolchain.com/). The use case here is to retrieve the main product attributes, plus associated tracking information for any product data stored using a ViD

## What is included?

1) LWC connector reading directly from ToolChain without storing any data on Salesforce
2) LWC, APEX class and custom objects to read and write data from ToolChain on Salesforce 

## What is not included?

1) Test classes for Apex
2) Support for any ToolChain
3) Configuration data, specifically the Custom Settings, Connected App settings and Process Builder Automations

## How to install?

1) Deploy LWCs, Objects and Apex on SF instance
2) Configure Remote Site and CSP settings to enable connection to https://v.vechain.com
3) Configure Process Builder Automation for calling Custom Apex when a new Track Info record is created, plus a queued 2nd call to process the results
5) Custom Settings, specifically to make the writing part more configurable

## Useful reference links

- https://docs.vetoolchain.com/hc/en-us/categories/360002659612-Product-and-Service
