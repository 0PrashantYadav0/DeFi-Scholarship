import { LaunchpadHeader } from "@/components/LaunchpadHeader";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader } from "@/components/ui/card";
import { MODULE_ADDRESS } from "@/constants";
import { aptosClient } from "@/utils/aptosClient";
import { InputViewFunctionData } from "@aptos-labs/ts-sdk";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { Form, Input, List, message, Select, Table } from "antd";
import "dotenv/config";
import { useEffect, useState } from "react";
const { Column } = Table;
import { Layout } from "antd";

const { Footer } = Layout;

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

interface ApplyScholarship {
  scholarship_id: number;
  criteria_gpa: number;
  field_of_study: string;
}

export function MyCollections() {
  const [scholarships, setScholarships] = useState<Scholarship[]>([]);
  const [appliedScholarships, setAppliedScholarships] = useState<{ appliedScholarshipIDS: string }[] | null>(null);

  const { account, signAndSubmitTransaction } = useWallet();

  useEffect(() => {
    fetchAllScholarships();
    view_all_scholarships_applied_by_address();
  }, []);

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

  const fetchAllScholarships = async () => {
    try {
      const payload: InputViewFunctionData = {
        function: `${MODULE_ADDRESS}::ScholarshipPlatform::view_all_scholarships`,
      };

      const result = await aptosClient().view({ payload });

      const scholarshipsList = result[0] as Scholarship[];

      setScholarships(scholarshipsList);
    } catch (error) {
      console.error("Failed to fetch scholarships:", error);
    } finally {
    }
  };

  const applyScholarship = async (values: ApplyScholarship) => {
    try {
      const transaction = await signAndSubmitTransaction({
        sender: account?.address,
        data: {
          function: `${MODULE_ADDRESS}::ScholarshipPlatform::apply_for_scholarship`,
          functionArguments: [values.scholarship_id, values.criteria_gpa, values.field_of_study],
        },
      });

      console.log("Transaction:", transaction);
      message.success(`Successfully To Scholarship! ${values.scholarship_id}`);

      fetchAllScholarships(); // Refresh scholarships
    } catch (error) {
      if (typeof error === "object" && error !== null && "code" in error && (error as { code: number }).code === 4001) {
        // Standard error code for user rejection
        message.error("Transaction rejected by user.");
      } else {
        if (error instanceof Error) {
          console.error(`Transaction failed: ${error.message}`);
        } else {
          console.error("Transaction failed: Unknown error");
        }
        console.error("Transaction Error:", error);
      }
      console.log("Error applying scholarship.", error);
    }
  };

  const view_all_scholarships_applied_by_address = async () => {
    try {
      const payload: InputViewFunctionData = {
        function: `${MODULE_ADDRESS}::ScholarshipPlatform::view_all_scholarships_applied_by_address`,
        functionArguments: [account?.address],
      };

      const result = await aptosClient().view({ payload });

      console.log("all scholarships applied by address:", result);

      const scholarshipIDS = result.map((scholarshipIDS) => ({
        appliedScholarshipIDS: String(scholarshipIDS),
        // gpa: 3.5, // Placeholder for GPA (or fetch from another function if available)
      }));

      setAppliedScholarships(scholarshipIDS as { appliedScholarshipIDS: string }[]);
      console.log("Applicant Data:", scholarshipIDS);
    } catch (error) {
      if (typeof error === "object" && error !== null && "code" in error && (error as { code: number }).code === 4001) {
        // Standard error code for user rejection
        message.error("Transaction rejected by user.");
      } else {
        if (error instanceof Error) {
          console.error(`Transaction failed: ${error.message}`);
        } else {
          console.error("Transaction failed: Unknown error");
        }
        console.error("Transaction Error:", error);
      }
      console.error("Failed to get applied Scholarship ids:", error);
    }
  };

  return (
    <>
      <LaunchpadHeader title="Apply for Scholarship" />
      <div className="flex flex-col items-center justify-center px-4 py-2 gap-4 max-w-screen-xl mx-auto">
        <div className="w-full flex flex-col gap-y-4">
          <Card>
            <CardHeader>
              <CardDescription>All Available Scholarships on the Platform</CardDescription>
            </CardHeader>
            <CardContent>
              <Table dataSource={scholarships} rowKey="scholarship_id" className="max-w-screen-xl mx-auto">
                <Column title="ID" dataIndex="scholarship_id" />
                <Column title="Name" dataIndex="name" />
                <Column
                  title="Donor"
                  dataIndex="donor"
                  render={(donor: string) => donor.substring(0, 6)}
                  responsive={["lg"]}
                />
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
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardDescription>Apply for Scholarship</CardDescription>
            </CardHeader>
            <CardContent>
              <Form
                onFinish={applyScholarship}
                labelCol={{
                  span: 3.5,
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
                <Form.Item name="criteria_gpa" label="GPA" rules={[{ required: true }]}>
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

                <Form.Item>
                  <Button variant="submit" size="lg" className="text-base" type="submit">
                    Apply for Scholarship
                  </Button>
                </Form.Item>
              </Form>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardDescription>All Applied Scholarships</CardDescription>
            </CardHeader>
            <CardContent>
              {appliedScholarships && appliedScholarships.length > 0 && (
                <List
                  grid={{ gutter: 16, column: 1 }}
                  dataSource={appliedScholarships}
                  renderItem={(applicant, i) => (
                    <List.Item>
                      <p>
                        <strong>Scholarship Id:{i}</strong> {applicant.appliedScholarshipIDS}
                      </p>
                    </List.Item>
                  )}
                />
              )}
            </CardContent>
          </Card>
        </div>
      </div>
      <Footer className="footer">Scholarship Platform ©2024 | All Rights Reserved</Footer>
    </>
  );
}
