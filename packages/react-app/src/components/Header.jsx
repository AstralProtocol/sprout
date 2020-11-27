import React from "react";
import { PageHeader } from "antd";

export default function Header() {
  return (
    <a href="https://github.com/austintgriffith/scaffold-eth" target="_blank" rel="noopener noreferrer">
      <PageHeader
        title="🌱 Smart Green Bond"
        subTitle="Enabling the issuance and repayment of a green bond on Ethereum"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
