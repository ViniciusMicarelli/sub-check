import { createRoot } from 'react-dom/client'
import { LanguageProvider } from '../i18n'
import { SupportPage } from '../components/Docs'
import '../styles.css'

createRoot(document.getElementById('root')).render(
  <LanguageProvider>
    <SupportPage />
  </LanguageProvider>,
)
