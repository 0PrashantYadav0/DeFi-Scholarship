import { Button, buttonVariants } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { WalletSelector } from "./WalletSelector";
import { useState } from "react";
import ChatBot from "./ChatBot";

export function Header() {
  const [chatBot, setChatBot] = useState<boolean>(false);

  const handleClick = () => {
    setChatBot(!chatBot);
  };

  return (
    <div className="flex items-center backdrop-blur-lg justify-between px-4 py-2 max-w-screen-xl mx-auto w-full flex-wrap md:flex-nowrap">
      <h1 className="display font-mono">
        <Link to="/" style={{ fontFamily: "unset" }}>
          De-Fi Scholarship
        </Link>
      </h1>

      <div className="flex gap-2 items-center">
        <>
          <Link className={buttonVariants({ variant: "link" })} to={"/create-scholarship"}>
            Create
          </Link>
          <Button variant={"link"} onClick={handleClick}>ChatBot</Button>
          <Link className={buttonVariants({ variant: "link" })} to={"/apply"}>
            Apply here
          </Link>
        </>
        <WalletSelector />
        {chatBot && <ChatBot />}
      </div>
    </div>
  );
}
