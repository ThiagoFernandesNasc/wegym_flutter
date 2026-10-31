import { revalidateTag } from "next/cache";
import { NextResponse } from "next/server";

export async function POST(request: Request) {
  try {
    const { tag } = await request.json();
    if (tag) {
      revalidateTag(tag, "max");
      return NextResponse.json({ revalidated: true, tag });
    }
    return NextResponse.json({ error: "Tag required" }, { status: 400 });
  } catch {
    return NextResponse.json({ error: "Invalid request" }, { status: 400 });
  }
}