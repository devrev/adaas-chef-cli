# Mapping Platform Groups

## Overview
This document outlines the process for developers to map their external default groups to internal platform groups using the new mapping object. This functionality allows for flexible integration with the platform's permission system while allowing for re-mapping by the end user. You are able to map to groups created by default by the DevRev platform, for example to the *Dev users* and the *Rev users* groups. 

## Implementation Guide

1. Developers need to create a mapping between their external default groups and the platform's internal default groups using a new mapping object. 
   - To do this define a new object in external metadata. 
   - The object should have one enum field with the possible values being the default groups available in external system.  
2. Developers can use IDM to map their object to the platform groups object in devrev (e.g.: to dev users and rev users groups).
3. The platform groups object can be referenced in other objects, for example in the shared_with field of articles.
