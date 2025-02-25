import { Organisation } from "@/context/types";

export const bigintToRole = (roleId: bigint, organisation: Organisation): string  => {
  console.log("bigintToRole triggered, waypoint 1: ", {roleId, organisation})

  const roleIds = organisation.roleLabels.map(roleLabel => roleLabel.roleId) 
  console.log("bigintToRole triggered, waypoint 2: ", {roleIds})

  const roleLabel = 
    roleId == 4294967295n ? "Public" 
    :
    roleId == 0n ? "Admin" 
    :
    roleIds.includes(roleId) ? organisation.roleLabels.find(roleLabel => roleLabel.roleId == roleId)?.label : `Role ${Number(roleId)}`

  console.log("bigintToRole triggered, waypoint 3: ", {roleLabel})

  return roleLabel ? String(roleLabel).charAt(0).toUpperCase() + String(roleLabel).slice(1) : "Error" 
}