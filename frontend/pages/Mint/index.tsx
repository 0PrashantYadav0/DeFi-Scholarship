import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";

import { Header } from "@/components/Header";

import { Layout } from "antd";
import "../../App.css"; // Create a separate CSS file for styling if needed.

const { Footer } = Layout;

export function Mint() {
  const queryClient = useQueryClient();
  const { account } = useWallet();
  useEffect(() => {
    queryClient.invalidateQueries();
  }, [account, queryClient]);

  return (
    <>
      <Header />
      <div style={{ overflow: "hidden" }} className="overflow-hidden">
        
        <footer className="footer-container px-4 pb-6 w-full max-w-screen-xl mx-auto mt-6 md:mt-16 flex items-center justify-between">
          <p>Get in Touch ...</p>
        </footer>
        <Footer className="footer">Scholarship Platform ©2024 | All Rights Reserved</Footer>
      </div>
    </>
  );
}
