// External packages
import { isMobile, useWallet } from "@aptos-labs/wallet-adapter-react";
import { useEffect, useState } from "react";
// Internal utils
import { aptosClient } from "@/utils/aptosClient";
// Internal components
import { LaunchpadHeader } from "@/components/LaunchpadHeader";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
// Entry functions
import { MODULE_ADDRESS } from "@/constants";
import { InputViewFunctionData } from "@aptos-labs/ts-sdk";
import { DatePicker, Form, message, Select, Table } from "antd";
import moment from "moment";
const { Column } = Table;

export function CreateCollection() {
  // Wallet Adapter provider
  const { account, signAndSubmitTransaction } = useWallet();
  const [scholarships, setScholarships] = useState<Scholarship[]>([]);
  const [createdScholarships, setCreatedScholarships] = useState<Scholarship[]>([]);
  const [balance, setBalance] = useState<number>(0);
  const [transactionHash, setTransactionHash] = useState<any>(null);
  const [scholarshipId, setScholarshipId] = useState<number>(0);

  useEffect(() => {
    fetchBalance();
    fetchAllScholarships();
    fetchAllScholarshipsCreatedByAddress();
  }, []);

  interface Scholarship {
    name: string;
    amount_per_applicant: number;
    total_applicants: number;
    criteria_gpa: number;
    field_of_study: string;
    end_time: number;
    is_open: boolean;
    recipients: string[];
    scholarship_id: number;
  }

  interface DistributeScholarship {
    scholarship_id: number;
  }

  interface ScholarshipFormData {
    name: string;
    amount_per_applicant: number;
    total_applicants: number;
    criteria_gpa: number;
    field_of_study: string;
    end_time: number;
    scholarship_id: number;
  }

  const disabledDateTime = () => {
    const now = moment();
    return {
      disabledHours: () => [...Array(24).keys()].slice(0, now.hour()),
      disabledMinutes: (selectedHour: number) => {
        if (selectedHour === now.hour()) {
          return [...Array(60).keys()].slice(0, now.minute());
        }
        return [];
      },
      disabledSeconds: (selectedHour: number, selectedMinute: number) => {
        if (selectedHour === now.hour() && selectedMinute === now.minute()) {
          return [...Array(60).keys()].slice(0, now.second());
        }
        return [];
      },
    };
  };

  function formatTimestamp(timestamp: number) {
    const date = new Date(Number(timestamp * 1000));
    const day = String(date.getDate()).padStart(2, "0");
    const month = date.toLocaleString("en-US", { month: "short" }).toUpperCase();
    const year = date.getFullYear();
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    const returnDate = `${day} ${month} ${year} ${hours}:${minutes}`;

    return returnDate;
  }

  const disabledDate = (current: any) => {
    // Can not select days before today and today
    return current && current < moment().endOf("day");
  };

  const initializeBalance = async () => {
    try {
      if (!account) throw new Error("Please connect your wallet");
      const response = await signAndSubmitTransaction({
        sender: account.address,
        data: {
          function: `${MODULE_ADDRESS}::ScholarshipPlatform::initialize_balance`,
          functionArguments: [],
        },
      });
      message.success("Balance initialized successfully!");
      await aptosClient().waitForTransaction({ transactionHash: response.hash });
      setTransactionHash(response.hash);
      console.log("Balance initialized!");
    } catch (error) {
      if (typeof error === "object" && error !== null && "code" in error && (error as { code: number }).code === 4001) {
        console.error("Transaction rejected by user. You Already Initialized Balance");
        message.error("Transaction rejected by user. You Already Initialized Balance");
      } else {
        if (error instanceof Error) {
          console.error(`Transaction failed: ${error.message}`);
        } else {
          console.error("Transaction failed: Unknown error");
        }
        console.error("Transaction Error:", error);
      }
    }
  };

  const createScholarship = async (values: ScholarshipFormData) => {
    setTransactionHash(null);
    try {
      const datePicker = values.end_time.toString();
      const timestamp = Date.parse(datePicker);
      const end_time = timestamp / 1000;
      const scholarship_id = 1000 + scholarshipId;
      const transaction = await signAndSubmitTransaction({
        sender: account?.address,
        data: {
          function: `${MODULE_ADDRESS}::ScholarshipPlatform::create_scholarship`,
          functionArguments: [
            scholarship_id,
            values.name,
            values.amount_per_applicant,
            values.total_applicants,
            values.criteria_gpa,
            values.field_of_study,
            end_time,
          ],
        },
      });

      await aptosClient().waitForTransaction({ transactionHash: transaction.hash });
      setTransactionHash(transaction.hash);
      message.success("Scholarship created!");
      fetchAllScholarships();
    } catch (error) {
      if (typeof error === "object" && error !== null && "code" in error && (error as { code: number }).code === 4001) {
        message.error("Transaction rejected by user.");
      } else {
        if (error instanceof Error) {
          console.error(`Transaction failed: ${error.message}`);
        } else {
          console.error("Transaction failed: Unknown error");
        }
        console.error("Transaction Error:", error);
      }
      console.log("Error creating scholarship.", error);
    } finally {
    }
  };

  const fetchAllScholarships = async () => {
    try {
      const payload: InputViewFunctionData = {
        function: `${MODULE_ADDRESS}::ScholarshipPlatform::view_all_scholarships`,
      };

      const result = await aptosClient().view({ payload });

      if (result[0]) {
        if (Array.isArray(result[0])) {
          setScholarshipId(result[0].length);
        } else {
          setScholarshipId(0);
        }
      }

      const scholarshipsList = result[0] as Scholarship[];

      setScholarships(scholarshipsList);
      console.log(scholarships);
    } catch (error) {
      console.error("Failed to fetch scholarships:", error);
    } finally {
    }
  };

  const fetchAllScholarshipsCreatedByAddress = async () => {
    try {
      const payload: InputViewFunctionData = {
        function: `${MODULE_ADDRESS}::ScholarshipPlatform::view_all_scholarships_created_by_address`,
        functionArguments: [account?.address],
      };

      const result = await aptosClient().view({ payload });

      const scholarshipsList = result[0] as Scholarship[];

      setCreatedScholarships(scholarshipsList);
    } catch (error) {
      console.error("Failed to fetch scholarships:", error);
    } finally {
    }
  };

  const issueTokens = async () => {
    const issueAmt = 10000000000;

    const response = await signAndSubmitTransaction({
      sender: account?.address,
      data: {
        function: `${MODULE_ADDRESS}::ScholarshipPlatform::issue_tokens`,
        functionArguments: [issueAmt],
      },
    });
    message.success("tokens Issued successfully!");
    setBalance(balance + issueAmt);

    await aptosClient().waitForTransaction(response.hash);
  };

  const initializeScholarship = async () => {
    try {
      const response = await signAndSubmitTransaction({
        sender: account?.address,
        data: {
          function: `${MODULE_ADDRESS}::ScholarshipPlatform::initialize_scholarships`,
          functionArguments: [],
        },
      });
      message.success("Initialized Scholarship successfully!");

      await aptosClient().waitForTransaction(response.hash);
    } catch (error) {
      if (typeof error === "object" && error !== null && "code" in error && (error as { code: number }).code === 4001) {
        message.error("Transaction rejected by user. You already Initialized Scholarship");
        console.error("Transaction rejected by user. You already Initialized Scholarship");
      } else {
        if (error instanceof Error) {
          console.error(`Transaction failed: ${error.message}`);
        } else {
          console.error("Transaction failed: Unknown error");
        }
        console.error("Transaction Error:", error);
      }
    }
  };

  const fetchBalance = async () => {
    try {
      const result = await aptosClient().view({
        payload: {
          function: `${MODULE_ADDRESS}::ScholarshipPlatform::view_account_balance`,
          functionArguments: [account?.address],
        },
      });

      if (Array.isArray(result) && result.length > 0) {
        setBalance(Number(result[0]));
      } else {
        setBalance(0);
      }
    } catch (error) {
      if (typeof error === "object" && error !== null && "code" in error && (error as { code: number }).code === 4001) {
        console.error("Transaction rejected by user.");
      } else {
        if (error instanceof Error) {
          console.error(`Transaction failed: ${error.message}`);
        } else {
          console.error("Transaction failed: Unknown error");
        }
        console.error("Transaction Error:", error);
      }
      console.error("Failed to get account balance:", error);
    }
  };

  const distributeScholarship = async (values: DistributeScholarship) => {
    setTransactionHash(null);
    try {
      const transaction = await signAndSubmitTransaction({
        sender: account?.address,
        data: {
          function: `${MODULE_ADDRESS}::ScholarshipPlatform::distribute_scholarship`,
          functionArguments: [values.scholarship_id],
        },
      });

      const txnHash = transaction?.hash;

      console.log(transaction?.hash);
      console.log(transaction);

      if (txnHash) {
        setTransactionHash(txnHash);
        console.log(transactionHash);
      }

      if (transaction?.hash) {
        const transactionResult = await aptosClient().waitForTransaction(transaction.hash);
        console.log(transactionResult);
        console.error("Scholarship Distributed successfully!");
      } else {
        throw new Error("Transaction hash is undefined");
      }
      message.success("Scholarship has been Distributed!");
      fetchAllScholarships();
    } catch (error) {
      if (typeof error === "object" && error !== null && "code" in error && (error as { code: number }).code === 4001) {
        message.error("Transaction rejected by user.");
      } else {
        if (error instanceof Error) {
          console.error(`Transaction failed: ${error.message}`);
        } else {
          console.error("Transaction failed: Unknown error");
        }
        console.error("Transaction Error:", error);
      }
      console.log("Error distributing scholarship.", error);
      console.error("Error distributing scholarship.");
    } finally {
    }
  };

  const emergency_close_scholarship = async (values: DistributeScholarship) => {
    setTransactionHash(null);
    try {
      const transaction = await signAndSubmitTransaction({
        sender: account?.address,
        data: {
          function: `${MODULE_ADDRESS}::ScholarshipPlatform::emergency_close_scholarship`,
          functionArguments: [values.scholarship_id],
        },
      });

      const txnHash = transaction?.hash;

      console.log(transaction?.hash);
      console.log(transaction);

      if (txnHash) {
        setTransactionHash(txnHash);
        console.log(transactionHash);
      }

      if (transaction?.hash) {
        const transactionResult = await aptosClient().waitForTransaction(transaction.hash);
        console.log(transactionResult);
        message.success("Scholarship Closed successfully!");
      } else {
        throw new Error("Transaction hash is undefined");
      }
      message.success("Scholarship has been Closed and Your money refunded!");
      fetchAllScholarships();
    } catch (error) {
      if (typeof error === "object" && error !== null && "code" in error && (error as { code: number }).code === 4001) {
        console.error("Transaction rejected by user.");
      } else {
        if (error instanceof Error) {
          console.error(`Transaction failed: ${error.message}`);
        } else {
          console.error("Transaction failed: Unknown error");
        }
        console.error("Transaction Error:", error);
      }
      console.log("Error Closing scholarship.", error);
      message.error("Error Closing scholarship.");
    } finally {
    }
  };

  return (
    <>
      <LaunchpadHeader title="Create Scholarships" />
      <div className="flex flex-col items-center justify-center px-4 py-2 gap-4 max-w-screen-xl mx-auto">
        <div className="w-full flex flex-col gap-y-4">
          <Card>
            <CardHeader>
              <CardDescription>Necessary functions to create scholarships only once per account</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex flex-col md:flex-row items-start justify-between space-y-4 md:space-y-0 md:space-x-4">
                <Button variant="init" size="sm" className="text-primary" onClick={initializeBalance}>
                  Initialize Balance
                </Button>

                <Button variant="init" size="sm" className="text-primary" onClick={issueTokens}>
                  Issue Tokens
                </Button>

                <Button variant="init" size="sm" className="text-primary" onClick={initializeScholarship}>
                  Init Scholarship
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardDescription>Your Balance for Scholarship Creation</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex flex-col md:flex-row items-start justify-between space-y-4 md:space-y-0 md:space-x-4">
                {balance !== 0 && <div>Tokens: {balance}</div>}
              </div>
            </CardContent>
          </Card>

          <h1>Create Scholarship</h1>
          <Form
            onFinish={createScholarship}
            labelCol={{
              span: 6.2,
            }}
            wrapperCol={{
              span: 100,
            }}
            layout="horizontal"
            style={{
              maxWidth: 1000,
              border: "1px solid #e5e7eb",
              borderRadius: "0.5rem",
              padding: "1.7rem",
            }}
          >
            <Form.Item name="name" label="Scholarship Name" rules={[{ required: true }]}>
              <Input />
            </Form.Item>
            <Form.Item name="amount_per_applicant" label="Amount Per Applicant" rules={[{ required: true }]}>
              <Input />
            </Form.Item>
            <Form.Item name="total_applicants" label="Total Applicants" rules={[{ required: true }]}>
              <Input />
            </Form.Item>
            <Form.Item name="criteria_gpa" label="Minimum GPA" rules={[{ required: true }]}>
              <Input />
            </Form.Item>
            <Form.Item name="field_of_study" label="Field of Study" rules={[{ required: true }]}>
              <Select>
                <Select.Option value="Science">Science</Select.Option>
                <Select.Option value="Maths">Maths</Select.Option>
                <Select.Option value="Computer">Computer</Select.Option>
                <Select.Option value="Sports">Sports</Select.Option>
                <Select.Option value="Others">Others</Select.Option>
              </Select>
            </Form.Item>
            <Form.Item name="end_time" label="End Time" rules={[{ required: true }]}>
              <DatePicker
                showTime={isMobile() ? false : true}
                disabledDate={disabledDate}
                disabledTime={disabledDateTime}
                getPopupContainer={(trigger) => trigger.parentElement || document.body}
                popupClassName="max-w-full sm:max-w-lg"
                className="w-full"
              />
            </Form.Item>
            <Form.Item>
              <Button variant="submit" size="lg" className="text-base w-full" type="submit">
                Create Scholarship
              </Button>
            </Form.Item>
          </Form>
          <Table dataSource={createdScholarships} rowKey="scholarship_id" className="max-w-screen-xl mx-auto">
            <Column title="ID" dataIndex="scholarship_id" />
            <Column title="Name" dataIndex="name" />
            <Column title="Amt / A" dataIndex="amount_per_applicant" responsive={["lg"]} />
            <Column title="Total A" dataIndex="total_applicants" responsive={["lg"]} />
            <Column title="GPA Req" dataIndex="criteria_gpa" />
            <Column title="Field" dataIndex="field_of_study" responsive={["md"]} />
            <Column
              title="Is Open"
              dataIndex="is_open"
              render={(is_open: boolean) => (is_open ? "Open" : "Closed")}
              responsive={["md"]}
            />
            <Column
              title="End Time"
              dataIndex="end_time"
              render={(time: any) => formatTimestamp(time).toString()}
              responsive={["lg"]}
            />
          </Table>
          <Card>
            <CardHeader>
              <CardDescription>Distribute Scholarship Funds after time Ended</CardDescription>
            </CardHeader>
            <CardContent>
              <Form
                onFinish={distributeScholarship}
                labelCol={{
                  span: 6.2,
                }}
                wrapperCol={{
                  span: 100,
                }}
                layout="horizontal"
                style={{
                  maxWidth: 1000,
                  border: "1px solid #e5e7eb",
                  borderRadius: "0.5rem",
                  padding: "1.7rem",
                }}
              >
                <Form.Item name="scholarship_id" label="Scholarship ID" rules={[{ required: true }]}>
                  <Input />
                </Form.Item>

                <Form.Item>
                  <Button variant="submit" size="lg" className="text-base" type="submit">
                    Distribute
                  </Button>
                </Form.Item>
              </Form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardDescription>Close Scholarship your funds will get refunded</CardDescription>
            </CardHeader>
            <CardContent>
              <Form
                onFinish={emergency_close_scholarship}
                labelCol={{
                  span: 6.2,
                }}
                wrapperCol={{
                  span: 100,
                }}
                layout="horizontal"
                style={{
                  maxWidth: 1000,
                  border: "1px solid #e5e7eb",
                  borderRadius: "0.5rem",
                  padding: "1.7rem",
                }}
              >
                <Form.Item name="scholarship_id" label="Scholarship ID" rules={[{ required: true }]}>
                  <Input />
                </Form.Item>

                <Form.Item>
                  <Button variant="submit" size="lg" className="text-base" type="submit">
                    Close
                  </Button>
                </Form.Item>
              </Form>
            </CardContent>
          </Card>
        </div>
      </div>
    </>
  );
}
