"use client";

import React, { useState } from "react";
import { AssetList } from "./AssetList";
import { AddAsset } from "./AddAsset";

export default function Page() {
  
  
    return (
      <main className="w-full h-full flex flex-col gap-12 justify-center items-center">
        <AssetList />
        <AddAsset /> 
      </main>
    )
}