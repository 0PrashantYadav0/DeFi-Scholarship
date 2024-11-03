import { useState } from "react";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { Input } from "@/components/ui/input"
import { Button } from "./ui/button";

const ChatBot = () => {

    const [aiPrompt, setAIPrompt] = useState<string>("");
    const [aiText, setAIText] = useState<string[]>([]);
    const [loading, setLoading] = useState<boolean>(false);

    const onAIprompt = async () => {
        if (!aiPrompt) return;
        setAIText([]);
        try {
            setLoading(true);
            const genAI = new GoogleGenerativeAI("AIzaSyBNO9xOo6VkKBf0XfV9MiUSXgyUWeU_juI");
            const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
    
            const result = await model.generateContent("You are a chatbot for an website for scholarship management. You have to help people to learn about your platform and how to use it. You can ask them questions about the platform, its features, or how to apply for scholarships. Your goal is to make them feel comfortable and confident using your platform. Provide solution to their problem in as minimum word as possible. Here is a prompt: "+aiPrompt);
    
            console.log(result);
            const aiGeneratedMarkdown = result.response.text(); 
    
            const aiGeneratedText = aiGeneratedMarkdown
                .replace(/\*\*(.*?)\*\*/g, '$1')
                .replace(/\*(.*?)\*/g, '$1')    
                .replace(/[-_*~`]/g, '');        
    
            const generatedText: string[] = aiGeneratedText
                .split('\n')
                .map((task: string) => task.trim()) 
                .filter((task: string) => task.length > 0);
    
            setAIText(generatedText); 
            setLoading(false);
        } catch (error: any) {
            setAIText([]);
            setLoading(false);
            console.log("AI error:", error);
        }
    };
    return (
        <div className="md:w-[70%] w-[100%] items-center justify-center absolute md:top-[40vh] md:left-[15%] top-[40vh] px-4 backdrop-blur-lg bg-gray-200 p-8 rounded-lg z-10">
            <div className="flex items-center justify-center">
                <Input
                    placeholder="Enter your prompt here"
                    value={aiPrompt}
                    onChange={(e: any) => setAIPrompt(e.target.value)}
                />
                <Button onClick={onAIprompt} disabled={loading}>{loading ? "loading" : "Ask AI" }</Button>
            </div>
            <div className="p-4 flex gap-4 flex-col justify-center">
                {aiText.map((task: string, index: number) => (
                    <div key={index}>
                        <p>{task}</p>
                    </div>
                ))}
            </div>
        </div>
    )
}

export default ChatBot
