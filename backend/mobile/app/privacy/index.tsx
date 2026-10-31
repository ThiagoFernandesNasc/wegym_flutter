import { ScrollView, Text, View, TouchableOpacity, Alert } from "react-native";
import { Stack } from "expo-router";
import { exportUserData, requestDataDeletion } from "@/api/privacy";

export default function PrivacyScreen() {
  const handleExport = async () => {
    try {
      const res = await exportUserData();
      Alert.alert("Dados exportados", "Seus dados serão enviados para seu email em instantes.");
    } catch { Alert.alert("Erro", "Falha ao exportar dados"); }
  };

  const handleDelete = () => {
    Alert.alert("Excluir dados", "Tem certeza? Esta ação é irreversível.", [
      { text: "Cancelar", style: "cancel" },
      { text: "Excluir", style: "destructive", onPress: async () => {
        try { await requestDataDeletion(); Alert.alert("Solicitação enviada", "Seus dados serão excluídos em até 30 dias."); } catch { Alert.alert("Erro", "Falha ao solicitar exclusão"); }
      }},
    ]);
  };

  const sections = [
    { title: "1. Introdução", text: "Esta Política de Privacidade descreve como a WEGYM coleta, usa e protege suas informações pessoais." },
    { title: "2. Dados coletados", text: "Coletamos: nome, CPF, email, dados de saúde (peso, altura, frequência cardíaca), dados de treino, localização (GPS) e dados de pagamento." },
    { title: "3. Uso dos dados", text: "Seus dados são usados para: personalizar treinos, gerar estatísticas, recomendar exercícios, processar pagamentos e melhorar nossos serviços." },
    { title: "4. Compartilhamento", text: "Compartilhamos dados apenas quando exigido por lei, com seu consentimento, com personal trainers que você autorizar, e com processadores de pagamento." },
    { title: "5. Retenção", text: "Mantemos seus dados enquanto sua conta estiver ativa. Após exclusão, os dados são removidos em até 90 dias." },
    { title: "6. Seus direitos (LGPD)", text: "Você tem direito a: acessar, corrigir, excluir, portar, anonimizar, revogar consentimento e ser informado sobre compartilhamento." },
    { title: "7. Segurança", text: "Utilizamos criptografia SSL/TLS, hashing de senhas, acesso restrito a dados e monitoramento contínuo." },
    { title: "8. Cookies", text: "Utilizamos cookies essenciais para funcionamento da plataforma e cookies analíticos para melhorias. Você pode desabilitá-los nas configurações do navegador." },
    { title: "9. Contato", text: "Email: privacidade@wegym.com.br\nDPO: dpo@wegym.com.br" },
    { title: "10. Atualizações", text: "Esta política foi atualizada em Julho de 2026. Recomendamos revisá-la periodicamente." },
  ];

  return (
    <>
      <Stack.Screen options={{ title: "Privacidade" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 20 }}>Privacidade</Text>
          {sections.map((s, i) => (
            <View key={i} style={{ marginBottom: 20 }}>
              <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 6 }}>{s.title}</Text>
              <Text style={{ fontSize: 13, color: "#a1a1aa", lineHeight: 20 }}>{s.text}</Text>
            </View>
          ))}

          <View style={{ marginTop: 20, gap: 10 }}>
            <TouchableOpacity onPress={handleExport} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 16, alignItems: "center" }}>
              <Text style={{ color: "#ea580c", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>📤 Exportar meus dados</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={handleDelete} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#dc262620", borderRadius: 16, padding: 16, alignItems: "center" }}>
              <Text style={{ color: "#dc2626", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>🗑️ Solicitar exclusão de dados</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </>
  );
}
