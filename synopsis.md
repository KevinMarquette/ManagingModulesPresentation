# Publishing and Managing Modules in an Internal Repository

Setting up and publishing to an internal repository is much easier than most people expect. In this talk, I plan on covering why it's a good idea to use an internal repository to distribute modules. I will show how to publish modules to both a file share and a local nuget instance. The demo will show the user how to manually publish the module with the idea that it should be part of a CI/CD pipeline. We will address the idea of re-hosting public modules from the PSGallery as a way to gate them into your organization. We will also show how to bootstrap other systems to use the internal repository.
And then talk about the trials and tribulations of doing this in my organization.

# Mantra

Set the stage
Share the vision
Show the features
Show the business value
Call to action

# Slides

# Set the stage

We all work with powershell. As our skill grows so does our library of tools. We are left on our own on how to manage our libraries so we all do it a little bit differently. If you are part of a team, then you also need a way to distribute your changes to everyone.

So what options do we have?
* Email
* USB drives
* File Shares
* Source Control (Git)
* PSGallery

# Vision

What if we could use our own PSGallery?
* Find-Module
* Install-Module
* Locally install
* Auto loading

Show me the code:



# Features
How to publish a module

Publishing to a share

Publishing to a nuget feed
* azure
* proget
* container

Reference to a CI/CD pipeline

Re-hosting modules

Bootstrap process
