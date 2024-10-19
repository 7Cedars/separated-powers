"use client";

import React, { useState, useEffect } from "react";
import AdminDashboard from "@/components/shared/AdminActions";
import MemberActions from "@/components/shared/MemberActions";
import WhaleActions from "@/components/shared/WhaleActions";
import SeniorActions from "@/components/shared/SeniorActions";
import { getRole } from "../utils/blockchainUtils";
import { ethers } from "ethers";
import AdminActions from "@/components/shared/AdminActions";

// Connect to Ethereum provider (MetaMask)
const getSigner = async () => {
    if (typeof window.ethereum !== "undefined") {
        try {
            // Request account access if needed
            await window.ethereum.request({ method: "eth_requestAccounts" });

            // Get the provider (MetaMask)
            const provider = new ethers.providers.Web3Provider(window.ethereum);

            // Get the signer (the user's wallet)
            const signer = provider.getSigner();
            const network = await provider.getNetwork();
            console.log("Connected to network:", network.name);

            return signer;
        } catch (error) {
            console.error("Error connecting to MetaMask", error);
            return null;
        }
    } else {
        console.error("Ethereum provider (MetaMask) not found.");
        return null;
    }
};

const DashboardPage: React.FC = () => {
    const [role, setRole] = useState<string>(""); // Role can be Admin, Member, Whale, Senior, Guest
    const [loading, setLoading] = useState<boolean>(true);
    const [error, setError] = useState<string | null>(null); // State for errors

    useEffect(() => {
        const fetchRole = async () => {
            try {
                const signer = await getSigner();
                if (signer) {
                    const userAddress = await signer.getAddress();
                    console.log("User Address:", userAddress);

                    const role = await getRole(userAddress); // Fetch role using blockchain logic
                    console.log("Fetched role:", role);

                    if (!role) {
                        setRole("Guest"); // Set default role if no role is found
                    } else {
                        setRole(role);
                    }
                } else {
                    setRole("Guest");
                }
            } catch (err) {
                console.error("Error fetching role:", err);
                setError("Unable to fetch role. Please try again later.");
                setRole("Guest");
            } finally {
                setLoading(false);
            }
        };

        fetchRole();
    }, []);

    if (loading) {
        return <div>Loading...</div>;
    }

    if (error) {
        return <div>Error: {error}</div>;
    }

    return (
        <div className="p-4">
            <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
            {role === "Admin" && (
                <>
                    {/*<AdminActions />*/}
                    <h1>AdminActions</h1>
                </>
            )}
            {role === "Whale" && (
                <>
                    {/*<WhaleActions />*/}
                    <h1>WhaleActions</h1>
                </>
            )}
            {role === "Senior" && (
                <SeniorActions />
            )}
            {role === "Member" && <MemberActions />}
            {role === "Guest" && (
                <p>You do not have any role assigned. Please contact support.</p>
            )}
        </div>
    );
};

export default DashboardPage;
