import { useCallback, useEffect, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, KeyboardAvoidingView, Platform } from "react-native";
import { Stack } from "expo-router";
import { getFeed, createPost, toggleLike, addComment, type SocialPost } from "@/api/social";

export default function FeedScreen() {
  const [posts, setPosts] = useState<SocialPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [newPost, setNewPost] = useState("");
  const [commentText, setCommentText] = useState<Record<string, string>>({});
  const [expandedPost, setExpandedPost] = useState<string | null>(null);

  const load = useCallback(async () => {
    try { setPosts(await getFeed()); } catch { /* silent */ } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const handlePost = async () => {
    if (!newPost.trim()) return;
    await createPost(newPost);
    setNewPost(""); load();
  };

  const handleLike = async (postId: string) => {
    await toggleLike(postId);
    load();
  };

  const handleComment = async (postId: string) => {
    const text = commentText[postId]?.trim();
    if (!text) return;
    await addComment(postId, text);
    setCommentText((prev) => ({ ...prev, [postId]: "" }));
    load();
  };

  return (
    <>
      <Stack.Screen options={{ title: "Feed" }} />
      <KeyboardAvoidingView style={{ flex: 1, backgroundColor: "#09090b" }} behavior={Platform.OS === "ios" ? "padding" : undefined}>
        <ScrollView>
          <View style={{ padding: 20 }}>
            <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 20 }}>Feed</Text>

            <View style={{ flexDirection: "row", backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 12, gap: 8, marginBottom: 16 }}>
              <TextInput value={newPost} onChangeText={setNewPost} placeholder="O que você está compartilhando?" placeholderTextColor="#71717a" multiline style={{ flex: 1, fontSize: 14, color: "#fff" }} />
              <TouchableOpacity onPress={handlePost} disabled={!newPost.trim()} style={{ backgroundColor: newPost.trim() ? "#ea580c" : "#27272a", borderRadius: 12, padding: 12, alignSelf: "flex-end" }}>
                <Text style={{ color: "#fff", fontSize: 12 }}>➤</Text>
              </TouchableOpacity>
            </View>

            {loading ? <ActivityIndicator size="large" color="#ea580c" /> : posts.length === 0 ? (
              <View style={{ alignItems: "center", paddingTop: 60 }}>
                <Text style={{ fontSize: 48, marginBottom: 12 }}>💬</Text>
                <Text style={{ color: "#71717a", fontSize: 14 }}>Nenhuma publicação ainda</Text>
              </View>
            ) : posts.map((post) => {
              const isExpanded = expandedPost === post.id;
              return (
                <View key={post.id} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 12 }}>
                  <View style={{ flexDirection: "row", alignItems: "center", gap: 10, marginBottom: 12 }}>
                    <View style={{ width: 36, height: 36, borderRadius: 12, backgroundColor: "#ea580c33", alignItems: "center", justifyContent: "center" }}>
                      <Text style={{ color: "#ea580c", fontSize: 14, fontWeight: "900" }}>{post.user.displayName?.charAt(0) || "?"}</Text>
                    </View>
                    <View>
                      <Text style={{ fontSize: 13, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{post.user.displayName}</Text>
                      <Text style={{ fontSize: 10, color: "#71717a" }}>{new Date(post.createdAt).toLocaleDateString("pt-BR")}</Text>
                    </View>
                  </View>
                  {post.text && <Text style={{ fontSize: 14, color: "#d4d4d8", marginBottom: 12 }}>{post.text}</Text>}
                  <View style={{ flexDirection: "row", gap: 20, marginBottom: isExpanded ? 12 : 0 }}>
                    <TouchableOpacity onPress={() => handleLike(post.id)} style={{ flexDirection: "row", alignItems: "center", gap: 4 }}>
                      <Text style={{ fontSize: 14, color: post.likes.length > 0 ? "#e11d48" : "#71717a" }}>{post.likes.length > 0 ? "❤️" : "🤍"}</Text>
                      <Text style={{ fontSize: 12, color: "#71717a" }}>{post._count.likes}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity onPress={() => setExpandedPost(isExpanded ? null : post.id)} style={{ flexDirection: "row", alignItems: "center", gap: 4 }}>
                      <Text style={{ fontSize: 14, color: isExpanded ? "#ea580c" : "#71717a" }}>💬</Text>
                      <Text style={{ fontSize: 12, color: "#71717a" }}>{post._count.comments}</Text>
                    </TouchableOpacity>
                  </View>
                  {isExpanded && (
                    <View style={{ borderTopWidth: 1, borderTopColor: "#27272a", paddingTop: 12 }}>
                      {post.comments && post.comments.length > 0 && post.comments.map((c) => (
                        <View key={c.id} style={{ flexDirection: "row", gap: 8, paddingVertical: 6 }}>
                          <Text style={{ color: "#ea580c", fontSize: 10, fontWeight: "900" }}>{c.user.displayName}:</Text>
                          <Text style={{ color: "#a1a1aa", fontSize: 12, flex: 1 }}>{c.text}</Text>
                        </View>
                      ))}
                      <View style={{ flexDirection: "row", gap: 8, marginTop: 8 }}>
                        <TextInput value={commentText[post.id] || ""} onChangeText={(t) => setCommentText((prev) => ({ ...prev, [post.id]: t }))} placeholder="Adicionar comentário..." placeholderTextColor="#52525b" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 8, fontSize: 11, color: "#fff" }} />
                        <TouchableOpacity onPress={() => handleComment(post.id)} disabled={!commentText[post.id]?.trim()} style={{ backgroundColor: commentText[post.id]?.trim() ? "#ea580c" : "#27272a", borderRadius: 10, padding: 8, justifyContent: "center" }}>
                          <Text style={{ color: "#fff", fontSize: 12 }}>➤</Text>
                        </TouchableOpacity>
                      </View>
                    </View>
                  )}
                </View>
              );
            })}
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </>
  );
}
