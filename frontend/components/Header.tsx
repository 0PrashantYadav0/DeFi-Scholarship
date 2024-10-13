import { buttonVariants } from "@/components/ui/button";
import { Link } from "react-router-dom";
import { WalletSelector } from "./WalletSelector";

export function Header() {
  return (
    <div className="flex items-center justify-between px-4 py-2 max-w-screen-xl mx-auto w-full flex-wrap md:flex-nowrap">
      <h1 className="display">
        <Link to="/" style={{ fontFamily: "unset" }}>
          Aptos Scholarships
        </Link>
      </h1>

      <div className="flex gap-2 items-center">
        <>
          <Link className={buttonVariants({ variant: "link" })} to={"/create-scholarship"}>
            Create
          </Link>
          <Link className={buttonVariants({ variant: "link" })} to={"/apply"}>
            Apply here
          </Link>
        </>

        <WalletSelector />
      </div>
    </div>
  );
}
