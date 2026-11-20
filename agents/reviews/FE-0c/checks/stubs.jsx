// QA stubs for Radix dropdown, ./ui/button and lucide-react (not installable offline). The trigger renders its child.
import React from 'react';
const pass = ({ children }) => <>{children}</>;
export const DropdownMenu = pass, DropdownMenuTrigger = pass;
export const DropdownMenuContent = () => null, DropdownMenuLabel = () => null, DropdownMenuRadioGroup = () => null, DropdownMenuRadioItem = () => null;
export const Button = ({ variant, size, ...p }) => <button type="button" {...p} />;
const Icon = (p) => <svg {...p} />;
export const Monitor = Icon, Moon = Icon, Sun = Icon;
