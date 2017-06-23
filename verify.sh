#!/usr/bin/env bash

dotnet restore
dotnet clean
find . -name *.Tests.csproj -exec dotnet test {} --configuration Release \;
