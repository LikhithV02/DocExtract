import { FileText, History, Upload } from "lucide-react";
import { NavLink } from "./NavLink";

export const Navigation = () => {
  return (
    <nav className="border-b bg-card/80 backdrop-blur-md sticky top-0 z-50 shadow-soft">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-gradient-primary flex items-center justify-center shadow-soft">
              <FileText className="w-6 h-6 text-white" />
            </div>
            <span className="text-xl font-bold bg-gradient-primary bg-clip-text text-transparent">
              DocExtract
            </span>
          </div>

          <div className="flex gap-1">
            <NavLink
              to="/"
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all hover:bg-gradient-secondary hover:text-white"
              activeClassName="bg-gradient-primary text-white shadow-soft"
            >
              <Upload className="w-4 h-4" />
              <span className="hidden sm:inline">Extract</span>
            </NavLink>
            <NavLink
              to="/history"
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all hover:bg-gradient-secondary hover:text-white"
              activeClassName="bg-gradient-primary text-white shadow-soft"
            >
              <History className="w-4 h-4" />
              <span className="hidden sm:inline">History</span>
            </NavLink>
          </div>
        </div>
      </div>
    </nav>
  );
};
