//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace LFE.Model
{
    using System;
    using System.Collections.Generic;
    
    public partial class CERT_TemplatesLOV
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public CERT_TemplatesLOV()
        {
            this.CERT_CertificateLib = new HashSet<CERT_CertificateLib>();
        }
    
        public byte TemplateId { get; set; }
        public string Name { get; set; }
        public string ImageName { get; set; }
        public bool IsActive { get; set; }
        public System.DateTime AddOn { get; set; }
    
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<CERT_CertificateLib> CERT_CertificateLib { get; set; }
    }
}